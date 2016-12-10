(require-extension bind)
(use lolevel)
(use srfi-1)
(use posix)
(use irregex)

(define app-title "Fucking weeb")

(define video-player "mpv")

; default when no db
(define db '((version 0)
             (defaults ("mpv" "/home/jaume/videos/series/"))
             (items
               ((curr . 120)
                (total . 160)
                (name . "ranma")
                (path . "/home/jaume/videos/series/1-More/Ranma"))
               ((curr . 1)
                (total . 26)
                (name . "eva")
                (path . "/home/jaume/videos/series/0-Sorted/neon_genesis_evangelion-1080p-renewal_cat")))))

(define (get-item-list db)
  (cdr (assoc 'items db)))

(define (get-item db id)
  (list-ref (cdr (assoc 'items db)) id))

(define (add-item db curr total name dir)
  (set! db (append! (assoc 'items db) (list (list curr total name dir)))))

(define (remove-item db n)
  (define items (get-items db))
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

(define (get-dir item)
  (cdr (assoc 'path item)))

(define (set-dir item n)
  (set-cdr! (assoc 'path item) n))

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

(define app (gtk_application_new "org.gtk.example"
                                 G_APPLICATION_FLAGS_NONE))

(define window #f)

(define (clean window)
  (define child (gtk_bin_get_child window))
  (if child (gtk_widget_destroy child) #f))

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
        (print "error: file not found")
        (begin
          (set! f (format #f "~A~A" dir (car f)))
          (process-run video-player (list f)))))))

(define (watch id)
  (define item (get-item db id))
  (define dir (get-dir item))
  (find-ep dir (get-curr-ep item))
  (printf "watch ~A ~A~%" (get-name item) (get-curr-ep item)))

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
(define path-entry #f)
(define curr-entry #f)
(define total-entry #f)

(define-external
  (add_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define name (gtk_entry_get_text name-entry))
  (define path (gtk_entry_get_text path-entry))
  (define curr (or (string->number (gtk_entry_get_text curr-entry)) 0))
  (define total (or (string->number (gtk_entry_get_text total-entry))
                    (max curr 24)))
  (add-item db curr total name path)
  (build-main-screen window))

(define (add-edit-buttons form name path curr total)
  (define name-label (gtk_label_new "Name:"))
  (gtk_label_set_xalign name-label 1)
  (set! name-entry (gtk_entry_new))
  (gtk_entry_set_text name-entry name)
  (gtk_widget_set_hexpand name-entry 1)
  (gtk_grid_attach form name-label 0 0 1 1)
  (gtk_grid_attach form name-entry 1 0 3 1)

  (define path-label (gtk_label_new "Path:"))
  (gtk_label_set_xalign path-label 1)
  (set! path-entry (gtk_entry_new)) ; todo dir-picker
  (gtk_entry_set_text path-entry path)
  (gtk_widget_set_hexpand path-entry 1)
  (gtk_grid_attach form path-label 0 1 1 1)
  (gtk_grid_attach form path-entry 1 1 3 1)

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
  (gtk_grid_attach form total-entry 3 2 1 1))


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

  (add-edit-buttons form "" "" "1" "24")

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
  (define path (gtk_entry_get_text path-entry))
  (define curr (or (string->number (gtk_entry_get_text curr-entry)) 0))
  (define total (or (string->number (gtk_entry_get_text total-entry)) (max curr 24)))
  (define item (get-item db id))
  (set-name item name)
  (set-dir item path)
  (set-curr-ep item curr)
  (set-total-eps item total)
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

  (add-edit-buttons form (get-name item) (get-dir item)
                    (number->string (get-curr-ep item))
                    (number->string (get-total-eps item)))

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
  (go_settings
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  #f)

(define (build-main-screen window)
  (clean window)
  (define button-box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))

  (gtk_box_set_spacing button-box 20)
  (gtk_widget_set_margin_top button-box 20)
  (gtk_widget_set_margin_start button-box 20)
  (gtk_widget_set_margin_end button-box 20)
  (gtk_widget_set_margin_bottom button-box 20)

  (gtk_container_add window button-box)

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
  (gtk_box_pack_start button-box title-box 0 1 5)

  (define i 0)
  (for-each
    (lambda (item)
      (define vbutton (gtk_button_new_with_label (get-name item)))
      (define data i)
      (g_signal_connect vbutton "clicked" #$go_view
                        (address->pointer data))
      ;(gtk_container_add button-box vbutton)
      (gtk_box_pack_start button-box vbutton 0 1 5)
      (set! i (+ i 1)))
    (get-item-list db))
  (define hbutton (gtk_button_new_with_label "+"))
  (g_signal_connect hbutton "clicked" #$go_add #f)
  ;(gtk_container_add button-box hbutton)
  (gtk_box_pack_end button-box hbutton 0 1 5)
  (gtk_widget_show_all window))

(define-external
  (activate
    ((pointer "GtkApplication") app)
    (c-pointer data))
  void
  (set! window (gtk_application_window_new app))
  (gtk_window_set_type_hint window GDK_WINDOW_TYPE_HINT_DIALOG)
  (gtk_window_set_title window app-title)
  (gtk_window_set_default_size window 200 200)
  (build-main-screen window))

(g_signal_connect app "activate" #$activate #f)

(condition-case (load-db)
  [(exn file i/o) (print "couldn't load file")])
(define status (g_application_run app 0 #f))
(save-db)

(g_object_unref app)

