(require-extension bind)
(use lolevel)
(use srfi-1)
(use posix)
(use irregex)

(define app-title "Fucking weeb")

; default when no db
(define db '((version 0)
             (defaults
               (video-player . "mpv")
               (path . "/home/jaume/videos/series/"))
             (items
               ((curr . 120)
                (total . 160)
                (name . "ranma")
                (path . "/home/jaume/videos/series/1-More/Ranma"))
               ((curr . 1)
                (total . 26)
                (name . "eva")
                (path . "/home/jaume/videos/series/0-Sorted/neon_genesis_evangelion-1080p-renewal_cat")))))

;
; black magic
(define (get-db-node path db)
  (define node-p (cons db #f)) ; this is a box
  (define val
    (call/cc ; should we just catch the exception at trying to cdr #f?
      (lambda (return)
        (for-each
          (lambda (name)
            (define a (assoc name (car node-p)))
            (if a
              (set-car! node-p (cdr a))
              (return #f)))
          path)
        (car node-p))))
  (or val
      (begin
        ; TODO: handle error
        (print "bad bad")
        (print path)
        (print db))))

(define (get-default-video-player db)
  (get-db-node '(defaults video-player) db))

(define (set-default-video-player db player)
  (set-cdr! (assoc 'video-player (cdr (assoc 'defaults db))) player))

(define (get-default-path db)
  (get-db-node '(defaults path) db))

(define (set-default-path db path)
  (set-cdr! (assoc 'path (cdr (assoc 'defaults db))) path))

(define (get-item-list db)
  (cdr (assoc 'items db)))

(define (get-item db id)
  (list-ref (cdr (assoc 'items db)) id))

(define (add-item db curr total name path)
  (set! db (append! (assoc 'items db)
                    `(((curr . ,curr)
                       (total . ,total)
                       (name . ,name)
                       (path . ,path))))))

(define (remove-item db n)
  (define items (get-item-list db))
  (if (= n 0)
    (set! items (cdr items))
    (set-cdr! (list-tail items (- n 1)) (cdr (list-tail items n))))
  db)

(define (get-curr-ep item)
  (cdr (assoc 'curr item)))

(define (set-curr-ep item n)
  (set-cdr! (assoc 'curr item) n))

(define (get-total-eps item)
  (cdr (assoc 'total item)))

(define (set-total-eps item n)
  (set-cdr! (assoc 'total item) n))

(define (get-name item)
  (cdr (assoc 'name item)))

(define (set-name item n)
  (set-cdr! (assoc 'name item) n))

(define (get-path item)
  (cdr (assoc 'path item)))

(define (set-path item n)
  (set-cdr! (assoc 'path item) n))

(define (get-video-player item)
  (define p (assoc 'video-player item))
  (and p (cdr p)))

(define (set-video-player item v)
  (if (equal? v "")
    (set! item (alist-delete! 'video-player item))
    (if (get-video-player item)
      (set-cdr! (assoc 'video-player item) v)
      (set! item (append! item (list (cons 'video-player v)))))))

(define (save-db)
  (call-with-output-file "db"
   (lambda (port)
     (write db port)
     (newline port))))

(define (load-db)
  ; todo: check version and error out
    (call-with-input-file "db"
     (lambda (port)
      (set! db (read port)))))

(foreign-declare "#include <gtk/gtk.h>")

(bind-file "gtk3_bindings.h")

(define (clean window)
  (define child (gtk_bin_get_child window))
  (if child (gtk_widget_destroy child) #f))

(define (clean-box box)
  (define children (gtk_container_get_children box))
  (do ((iter children (_GList-next iter)))
      ((not iter) #f)
    (gtk_widget_destroy (_GList-data iter)))
  (g_list_free children))

(define-external
  (go_back
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (build-main-screen window))

(define (data->id data)
 (if data
   (pointer->address data)
   0))

(define-external
  (go_view
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (build-view-screen window id))

(define-external
  (go_add
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (build-add-screen window))

(define (find-ep dir num)
  (set! dir (irregex-replace "/*$" dir "/")) ; always 1 trailing slash
  (if (not (directory? dir))
    (print "error: not a directory")
    (begin
      (define file-list (directory dir #t))
      ; These are stolen from onodera's neet source
      (define r1
        (irregex (format #f "(e|ep|episode|第)[0 ]*~A[^0-9]" num)))
      (define r2
        (irregex (format #f "( |_|-|#|\\.)[0 ]*~A[^0-9]" num)))
      (define r3
        (irregex (format #f "~A[^0-9]" num)))
      (define f
        (filter (lambda (s) (irregex-search r1 s)) file-list))
      (define f
        (if (null? f)
          (filter (lambda (s) (irregex-search r2 s)) file-list)
          f))
      (define f
        (if (null? f)
          (filter (lambda (s) (irregex-search r3 s)) file-list)
          f))
      (if (null? f)
        (begin
          (print "error: file not found")
          #f)
        (begin
          (set! f (format #f "~A~A" dir (car f)))
          f)))))
          ;(process-run video-player (list f)))))))

(define (watch id)
  (define item (get-item db id))
  (define dir (get-path item))
  (define fn (find-ep dir (get-curr-ep item)))
  (printf "watch ~A ~A ~A~%" (get-name item) (get-curr-ep item) fn)
  (define video-player (or (get-video-player item)
                           (get-default-video-player db)))
  (if f
   (process-run video-player (list f))))

(define-external
  (watch_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (watch (data->id data)))

(define-external
  (watch_next_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (define item (get-item db id))
  (set-curr-ep item (min (get-total-eps item) (+ 1 (get-curr-ep item))))
  (watch id)
  (build-view-screen window id))

(define curr-spin #f)

(define-external
  (ep_num_changed
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (define item (get-item db id))
  (define new-val
    (gtk_spin_button_get_value_as_int curr-spin))
  (set-curr-ep item new-val))

(define name-entry #f)
(define selected-path #f)

(define curr-entry #f)
(define total-entry #f)
(define video-player-entry #f)

(define-external
  (add_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define name (gtk_entry_get_text name-entry))
  (define curr (or (string->number (gtk_entry_get_text curr-entry)) 0))
  (define total (or (string->number (gtk_entry_get_text total-entry))
                    (max curr 24)))
  (add-item db curr total name
    (or selected-path
        (get-default-path db)))
  (build-main-screen window))

(define-external
  (path_picked
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (set! selected-path
    (gtk_file_chooser_get_filename widget))
  (if (equal? "" (gtk_entry_get_text name-entry))
    (begin
      (define parts (irregex-split "/" selected-path))
      (if (not (null? parts))
        (gtk_entry_set_text name-entry (last parts))))))
  ; TODO: automagically set number of episodes

(define (add-edit-buttons form name path curr total video-player)
  (define name-label (gtk_label_new "Name:"))
  (gtk_label_set_xalign name-label 1)
  (set! name-entry (gtk_entry_new))
  (gtk_entry_set_text name-entry name)
  (gtk_widget_set_hexpand name-entry 1)
  (gtk_grid_attach form name-label 0 0 1 1)
  (gtk_grid_attach form name-entry 1 0 3 1)

  (define path-label (gtk_label_new "Path:"))
  (gtk_label_set_xalign path-label 1)

  (define path-picker
    (gtk_file_chooser_button_new "Select the search path"
                                 GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER))
  (set! selected-path #f)
  (g_signal_connect path-picker "file-set" #$path_picked #f)
  (if path
    (gtk_file_chooser_set_filename path-picker path))

  (gtk_widget_set_hexpand path-picker 1)

  (gtk_grid_attach form path-label 0 1 1 1)
  (gtk_grid_attach form path-picker 1 1 3 1)

  (define eps-label (gtk_label_new "Current episode:"))
  (gtk_label_set_xalign eps-label 1)
  (set! curr-entry (gtk_entry_new))
  (gtk_entry_set_text curr-entry curr)
  (gtk_widget_set_hexpand curr-entry 1)
  (define eps-slash (gtk_label_new "/"))
  (set! total-entry (gtk_entry_new))
  (gtk_entry_set_text total-entry total)
  (gtk_widget_set_hexpand total-entry 1)
  (gtk_grid_attach form eps-label 0 2 1 1)
  (gtk_grid_attach form curr-entry 1 2 1 1)
  (gtk_grid_attach form eps-slash 2 2 1 1)
  (gtk_grid_attach form total-entry 3 2 1 1)

  (define video-player-label (gtk_label_new "Video Player:"))
  (gtk_label_set_xalign video-player-label 1)
  (set! video-player-entry (gtk_entry_new))
  (gtk_entry_set_text video-player-entry video-player)
  (gtk_widget_set_hexpand video-player-entry 1)
  (gtk_grid_attach form video-player-label 0 3 1 1)
  (gtk_grid_attach form video-player-entry 1 3 3 1))


(define (build-add-screen window)
  (clean window)
  (define box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
  (gtk_box_set_spacing box 20)
  (gtk_widget_set_margin_top box 20)
  (gtk_widget_set_margin_start box 20)
  (gtk_widget_set_margin_end box 20)
  (gtk_widget_set_margin_bottom box 20)
  (gtk_container_add window box)

  (define form (gtk_grid_new))
  (gtk_grid_set_column_spacing form 20)
  (gtk_grid_set_row_spacing form 10)
  (gtk_box_pack_start box form 1 1 5)

  (add-edit-buttons form "" (get-default-path db) "1" "24" "")

  (define button-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define add-button (gtk_button_new_with_label "Add"))
  (define back-button (gtk_button_new_with_label "Cancel"))
  (gtk_box_pack_start button-box add-button 1 1 5)
  (gtk_box_pack_end button-box back-button 1 1 5)

  (gtk_box_pack_end box button-box 0 0 5)

  (g_signal_connect add-button "clicked" #$add_button #f)
  (g_signal_connect back-button "clicked" #$go_back #f)

  (gtk_widget_show_all window))

(define-external
  (save_edit_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (define name (gtk_entry_get_text name-entry))
  (define curr (or (string->number (gtk_entry_get_text curr-entry)) 0))
  (define total (or (string->number (gtk_entry_get_text total-entry)) (max curr 24)))
  (define video-player (gtk_entry_get_text video-player-entry))
  (define item (get-item db id))
  (set-name item name)
  (if selected-path
    (set-path item selected-path))
  (set-curr-ep item curr)
  (set-total-eps item total)
  (set-video-player item video-player)
  (build-view-screen window id))

(define (build-edit-screen window id)
  (clean window)
  (define box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
  (gtk_box_set_spacing box 20)
  (gtk_widget_set_margin_top box 20)
  (gtk_widget_set_margin_start box 20)
  (gtk_widget_set_margin_end box 20)
  (gtk_widget_set_margin_bottom box 20)
  (gtk_container_add window box)

  (define form (gtk_grid_new))
  (gtk_grid_set_column_spacing form 20)
  (gtk_grid_set_row_spacing form 10)
  (gtk_box_pack_start box form 1 1 5)

  (define item (get-item db id))

  (add-edit-buttons form (get-name item) (get-path item)
                    (number->string (get-curr-ep item))
                    (number->string (get-total-eps item))
                    (or (get-video-player item) ""))

  (define button-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define add-button (gtk_button_new_with_label "Save"))
  (define back-button (gtk_button_new_with_label "Cancel"))
  (gtk_box_pack_start button-box add-button 1 1 5)
  (gtk_box_pack_end button-box back-button 1 1 5)

  (gtk_box_pack_end box button-box 0 0 5)

  (g_signal_connect add-button "clicked" #$save_edit_button
                        (address->pointer id))
  (g_signal_connect back-button "clicked" #$go_view
                        (address->pointer id))

  (gtk_widget_show_all window))


(define-external
  (remove_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define confirm-dialog (gtk_message_dialog_new
                           window
                           0
                           GTK_MESSAGE_QUESTION
                           GTK_BUTTONS_OK_CANCEL
                           "Are you sure you want to delete this?"))
  (define response (gtk_dialog_run confirm-dialog))
  (gtk_widget_destroy confirm-dialog)
  (if (= response GTK_RESPONSE_OK)
    (begin
      (define id (data->id data))
      (set! db (remove-item db id))
      (build-main-screen window))))

(define-external
  (edit_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (build-edit-screen window id))

(define (build-view-screen window id)
  (clean window)
  (define box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
  (gtk_box_set_spacing box 10)
  (gtk_widget_set_margin_top box 20)
  (gtk_widget_set_margin_start box 20)
  (gtk_widget_set_margin_end box 20)
  (gtk_widget_set_margin_bottom box 20)
  (gtk_container_add window box)

  (define item (get-item db id))
  (define label (gtk_label_new (get-name item)))
  (gtk_box_pack_start box label 1 1 5)

  (define progress-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))

  (define curr-adj (gtk_adjustment_new
                     (get-curr-ep item) 1 (get-total-eps item) 1 0 0))
  (set! curr-spin (gtk_spin_button_new curr-adj 0 0))
  (gtk_box_pack_start progress-box curr-spin 0 1 5)
  (g_signal_connect
    curr-spin "value-changed" #$ep_num_changed #f)

  (define total-label (gtk_label_new (format #f "/ ~A" (get-total-eps item))))
  (gtk_box_pack_start progress-box total-label 0 1 5)

  (gtk_box_pack_start box progress-box 1 0 5)

  (gtk_widget_set_halign progress-box GTK_ALIGN_CENTER)

  (define button (gtk_button_new_with_label "watch"))
  (g_signal_connect button "clicked" #$watch_button (address->pointer id))
  (gtk_box_pack_start box button 0 1 2)
  (define button (gtk_button_new_with_label "watch next"))
  (g_signal_connect button "clicked" #$watch_next_button (address->pointer id))
  (gtk_box_pack_start box button 0 1 2)
  (define button (gtk_button_new_with_label "edit"))
  (gtk_box_pack_start box button 0 1 2)
  (g_signal_connect button "clicked" #$edit_button (address->pointer id))
  (define button (gtk_button_new_with_label "remove"))
  (gtk_box_pack_start box button 0 1 2)
  (g_signal_connect button "clicked" #$remove_button (address->pointer id))
  (define bbutton (gtk_button_new_with_label "back"))
  (gtk_widget_set_margin_top bbutton 20)
  (gtk_box_pack_end box bbutton 0 1 2)
  (g_signal_connect bbutton "clicked" #$go_back #f)

  (gtk_widget_show_all window))

(define-external
  (save_settings_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define video-player (gtk_entry_get_text video-player-entry))
  (set-default-video-player db video-player)
  (if selected-path
    (set-default-path db selected-path))
  (build-main-screen window))

(define (build-settings-screen window)
  (clean window)
  (define box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
  (gtk_box_set_spacing box 20)
  (gtk_widget_set_margin_top box 20)
  (gtk_widget_set_margin_start box 20)
  (gtk_widget_set_margin_end box 20)
  (gtk_widget_set_margin_bottom box 20)
  (gtk_container_add window box)

  (define form (gtk_grid_new))
  (gtk_grid_set_column_spacing form 20)
  (gtk_grid_set_row_spacing form 10)
  (gtk_box_pack_start box form 1 1 5)

  (define video-player (get-default-video-player db))
  (define video-player-label (gtk_label_new "Video Player:"))
  (gtk_label_set_xalign video-player-label 1)
  (set! video-player-entry (gtk_entry_new))
  (gtk_entry_set_text video-player-entry video-player)
  (gtk_widget_set_hexpand video-player-entry 1)
  (gtk_grid_attach form video-player-label 0 0 1 1)
  (gtk_grid_attach form video-player-entry 1 0 3 1)

  (define path (get-default-path db))
  (define path-label (gtk_label_new "Default Path:"))
  (gtk_label_set_xalign path-label 1)
  (define path-picker
    (gtk_file_chooser_button_new "Select the default path"
                                 GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER))
  (g_signal_connect path-picker "file-set" #$path_picked #f)
  (if path
    (gtk_file_chooser_set_filename path-picker path))
  (gtk_widget_set_hexpand path-picker 1)
  (gtk_grid_attach form path-label 0 1 1 1)
  (gtk_grid_attach form path-picker 1 1 3 1)

  (define button-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define add-button (gtk_button_new_with_label "Save"))
  (define back-button (gtk_button_new_with_label "Cancel"))
  (gtk_box_pack_start button-box add-button 1 1 5)
  (gtk_box_pack_end button-box back-button 1 1 5)

  (gtk_box_pack_end box button-box 0 0 5)

  (g_signal_connect add-button "clicked" #$save_settings_button #f)
  (g_signal_connect back-button "clicked" #$go_back #f)

  (gtk_widget_show_all window))

(define-external
  (go_settings
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (build-settings-screen window))

(define search-bar #f)

(define-external
  (search_changed
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (build-button-box)
  (gtk_widget_show_all window))

(define button-box #f)

(define (build-button-box)
  (clean-box button-box)

  (define regex (irregex (gtk_entry_get_text search-bar) 'i))
  (define (search-filter item)
    (irregex-search regex (get-name item)))

  ; add ids
  (define i 0)
  (define items
    (map (lambda (item)
           (begin
             (define new-item (alist-cons 'id i item))
             (set! i (+ 1 i))
             new-item))
         (get-item-list db)))

  (define items (filter search-filter items))

  (for-each
    (lambda (item)
      (define vbutton (gtk_button_new_with_label (get-name item)))
      (define data (cdr (assoc 'id item)))
      (g_signal_connect vbutton "clicked" #$go_view
                        (address->pointer data))
      ;(gtk_container_add button-box vbutton)
      (gtk_box_pack_start button-box vbutton 0 1 5))
    items)
  (define hbutton (gtk_button_new_with_label "+"))
  (g_signal_connect hbutton "clicked" #$go_add #f)
  ;(gtk_container_add button-box hbutton)
  (gtk_box_pack_end button-box hbutton 0 1 5))

(define (build-main-screen window)
  (clean window)

  (define main-box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))

  (gtk_container_add window main-box)

  ;(gtk_container_add window scrollable)

  (gtk_box_set_spacing main-box 20)
  (gtk_widget_set_margin_top main-box 20)
  (gtk_widget_set_margin_start main-box 20)
  (gtk_widget_set_margin_end main-box 20)
  (gtk_widget_set_margin_bottom main-box 20)

  ; Title and settings
  (define title-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define title-label (gtk_label_new app-title))
  (define title-attrs (pango_attr_list_new))
  (define attr-weight (pango_attr_weight_new PANGO_WEIGHT_BOLD))
  (pango_attr_list_insert title-attrs attr-weight)
  (define attr-scale (pango_attr_scale_new 1.5))
  (pango_attr_list_insert title-attrs attr-scale)
  (gtk_label_set_attributes title-label title-attrs)
  ; should I actually free this myself? it segfaults! scary scary
  ;(pango_attribute_destroy attr)
  (pango_attr_list_unref title-attrs)
  (gtk_box_pack_start title-box title-label 1 1 10)
  (define settings-button (gtk_button_new_from_icon_name
                            "gtk-preferences"
                            GTK_ICON_SIZE_BUTTON))
  (g_signal_connect settings-button "clicked" #$go_settings #f)
  (gtk_box_pack_start title-box settings-button 0 1 0)
  (gtk_box_pack_start main-box title-box 0 1 5)

  ; search bar
  (set! search-bar (gtk_search_entry_new))
  (gtk_box_pack_start main-box search-bar 0 1 5)
  (g_signal_connect search-bar "search-changed" #$search_changed #f)

  (define scrollable (gtk_scrolled_window_new #f #f))
  (define viewport (gtk_viewport_new #f #f))
  (gtk_container_add scrollable viewport)

  (gtk_box_pack_start main-box scrollable 1 1 5)

  (set! button-box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
  (gtk_container_add viewport button-box)

  (gtk_box_set_spacing button-box 20)

  (build-button-box)

  (gtk_widget_show_all window))

(define-external
  (destroy
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (gtk_main_quit))

(condition-case (load-db)
  [(exn file i/o) (print "couldn't load file")])
(gtk_init #f #f)
(define window (gtk_window_new GTK_WINDOW_TOPLEVEL))
(g_signal_connect window "destroy" #$destroy #f)
(gtk_window_set_type_hint window GDK_WINDOW_TYPE_HINT_DIALOG)
(gtk_window_set_title window app-title)
(gtk_window_set_default_size window 300 500)
(build-main-screen window)

(gtk_main)

(save-db)

