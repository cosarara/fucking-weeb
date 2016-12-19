; Fucking Weeb
; Copyright © Jaume Delclòs Coll

; This file is part of Fucking Weeb.
;
; Fucking Weeb is free software: you can redistribute it and/or modify
; it under the terms of the GNU General Public License as published by
; the Free Software Foundation, either version 3 of the License, or
; (at your option) any later version.
;
; Fucking Weeb is distributed in the hope that it will be useful,
; but WITHOUT ANY WARRANTY; without even the implied warranty of
; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
; GNU General Public License for more details.
;
; You should have received a copy of the GNU General Public License
; along with Fucking Weeb.  If not, see <http://www.gnu.org/licenses/>.

; The code is organised as follows:
; 1 - DATABASE
; 2 - FILESYSTEM & XDG
; 3 - GTK
; 3.1 - Main Screen
; 3.1.1 - Poster List
; 3.2 - Settings Screen
; 3.3 - View Screen
; 3.4 - Add New Screen
; 3.5 - Edit Screen
; 3.6 - Add/Edit controls
; 3.7 - The Movie DB
; 3.8 - Drag & Drop
; 3.9 - Gtk Entry & exit points

; Gtk callbacks are C functions and have to be declared
; before functions that use them. Thus, every section will
; have some callbacks (or not), then the actual function
; implementing the feature (rendering a screen or whatever).

(require-extension bind)
(use lolevel)
(use srfi-1)
(use srfi-13)
(use srfi-18)
(use posix)
(use irregex)
(use http-client)
(use uri-common)
(use medea)

(define app-title "Fucking weeb")

; DATABASE

; default when no db
(define db '((version 0)
             (autoplay . #t)
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

(define (get-autoplay db)
  (let ((i (assoc 'autoplay db)))
   (and i (cdr i))))

(define (set-autoplay db autoplay)
  (let ((i (assoc 'autoplay db)))
    (if i
      (set-cdr! i autoplay)
      (set! db (append! db (list (cons 'autoplay autoplay)))))))

(define (get-item-list db)
  (cdr (assoc 'items db)))

(define (set-item-list db items)
  (set-cdr! (assoc 'items db) items))

(define (get-item db id)
  (list-ref (cdr (assoc 'items db)) id))

(define (add-item db curr total name path video-player cover)
  (define item
    `((curr . ,curr)
      (total . ,total)
      (name . ,name)
      (path . ,path)))
  (set-video-player item video-player)
  (set-cover item cover)

  (set! db (append! (assoc 'items db) (list item))))

(define (remove-item db n)
  (define items (get-item-list db))
  (if (= n 0)
    (set-item-list db (cdr items))
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

(define (get-cover item)
  (define p (assoc 'cover item))
  (and p (cdr p)))

(define (set-cover item v)
  (set! item (alist-delete! 'cover item))
  (set! item (append! item (list (cons 'cover v)))))


; FILESYSTEM & XDG

(define (ensure-trailing-slash dir) (irregex-replace "/*$" dir "/"))

(define xdg-app-name "fucking-weeb")

(define xdg-config
  (create-directory
    (format #f "~A~A/"
            (ensure-trailing-slash
              (or (get-environment-variable "XDG_CONFIG_HOME")
                  ; I shall assume $HOME is always defined
                  (format "~A/.config"
                          (get-environment-variable "HOME"))))
            xdg-app-name)))

(define xdg-data
  (create-directory
    (format #f "~A~A/"
            (ensure-trailing-slash
              (or (get-environment-variable "XDG_DATA_HOME")
                  ; I shall assume $HOME is always defined
                  (format "~A/.local/share"
                          (get-environment-variable "HOME"))))
            xdg-app-name)))

(define (save-db)
  (call-with-output-file (format #f "~Adb" xdg-config)
   (lambda (port)
     (write db port)
     (newline port))))

(define (load-db)
  ; todo: check version and error out
  (define path (format #f "~A/db" xdg-config))
  (call-with-input-file path
    (lambda (port)
      (set! db (read port)))))

; GTK

; todo get this at the bottom actually
(foreign-declare "#include <gtk/gtk.h>")

(bind-file "gtk3_bindings.h")
; Probably not the best way to do this.
(bind* #<<EOF
    GtkWidget* gtk_message_dialog_new_wrap
        (GtkWindow      *parent,
         GtkDialogFlags  flags,
         GtkMessageType  type,
         GtkButtonsType  buttons,
         const gchar    *message_format) {
         return gtk_message_dialog_new(parent, flags, type, buttons, "%s", message_format);
     }
EOF
)

(define (clean-container box)
  (define children (gtk_container_get_children box))
  (do ((iter children (_GList-next iter)))
      ((not iter) #f)
    (gtk_widget_destroy (_GList-data iter)))
  (g_list_free children))

; GTK - Main Screen

(define-external
  (go_settings
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (build-settings-screen window))

(define-external
  (search_changed
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (build-button-box)
  (gtk_widget_show_all window))

(define-external
  (go_add
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (build-add-screen window))

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
  (define title-label (make-title-label app-title))
  (gtk_box_set_center_widget title-box title-label)
  (define settings-button (gtk_button_new_from_icon_name
                            "gtk-preferences"
                            GTK_ICON_SIZE_BUTTON))
  (g_signal_connect settings-button "clicked" #$go_settings #f)
  (gtk_box_pack_end title-box settings-button 0 1 0)
  (gtk_box_pack_start main-box title-box 0 1 5)

  ; search bar
  (define search-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (gtk_box_pack_start main-box search-box 0 1 5)
  (set! search-bar (gtk_search_entry_new))

  (define search-bar-sc (gtk_widget_get_style_context search-bar))
  (define s-css-provider (gtk_css_provider_new))
  (gtk_css_provider_load_from_path
    s-css-provider
    (if (file-exists? "search.css")
      "search.css"
      (format #f "~A/search.css" (repository-path))) #f)
  (gtk_style_context_add_provider
    search-bar-sc s-css-provider
    GTK_STYLE_PROVIDER_PRIORITY_APPLICATION)

  (gtk_box_pack_start search-box search-bar 1 1 5)
  (g_signal_connect search-bar "search-changed" #$search_changed #f)

  (define scrollable (gtk_scrolled_window_new #f #f))
  (define viewport (gtk_viewport_new #f #f))
  (gtk_container_add scrollable viewport)

  (gtk_box_pack_start main-box scrollable 1 1 0)

  (set! button-box (gtk_flow_box_new))
  (gtk_flow_box_set_selection_mode button-box GTK_SELECTION_NONE)
  ;(set! button-box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
  (gtk_container_add viewport button-box)

  ;(gtk_box_set_spacing button-box 20)

  (build-button-box)

  (define add-button (gtk_button_new_from_icon_name
                       "gtk-add"
                       GTK_ICON_SIZE_BUTTON))
  (g_signal_connect add-button "clicked" #$go_add #f)
  (gtk_box_pack_end search-box add-button 0 1 0)

  (gtk_widget_show_all window))

; main window helper functions

(define (clean window)
  (define child (gtk_bin_get_child window))
  (if child (gtk_widget_destroy child) #f))

(define (make-title-label text)
  (define title-label (gtk_label_new text))
  ;(gtk_label_set_xalign title-label 0)
  (define title-attrs (pango_attr_list_new))
  (define attr-weight (pango_attr_weight_new PANGO_WEIGHT_BOLD))
  (pango_attr_list_insert title-attrs attr-weight)
  (define attr-scale (pango_attr_scale_new 1.5))
  (pango_attr_list_insert title-attrs attr-scale)
  (gtk_label_set_attributes title-label title-attrs)
  ; should I actually free this myself? it segfaults! scary scary
  ;(pango_attribute_destroy attr)
  (pango_attr_list_unref title-attrs)
  title-label)

; Poster List

(define-external
  (cover_button_press
    ((pointer "GtkWidget") widget)
    ((pointer "GdkEvent") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (build-view-screen window id))

(define-external
  (receive_drop_main
    ((pointer "GtkWidget") widget)
    (c-pointer context)
    (int x)
    (int y)
    (c-pointer data)
    (unsigned-int info)
    (unsigned-int time)
    (c-pointer user-data))
  void
  ; fixme free the string
  (define dropped-text
    (string-trim-both
      (my_gtk_selection_data_get_text data)))
  (define id (data->id user-data))
  (magic-drop-cover dropped-text id)
  (update-cover-main-screen id))

(define pixbuf-cache '())

(define (build-button-box)
  (clean-container button-box)

  (define regex (irregex (gtk_entry_get_text search-bar) 'i))
  (define (search-filter item)
    (irregex-search regex (get-name item)))

  ; download missing
  ;(map (lambda (item)
  ;       (if (not (get-cover item))
  ;         (begin
  ;           (format #t "Downloading cover for ~A~%" (get-name item))
  ;           (define image-path (download-image (get-name item)))
  ;           (print image-path)
  ;           (if image-path (set-cover item image-path))))
  ;     (get-item-list db)))

  ; add ids
  (define i 0)
  (define items
    (map (lambda (item)
           (begin
             (define new-item (alist-cons 'id i item))
             (set! i (+ 1 i))
             new-item))
         (get-item-list db)))

  (define items (sort (filter search-filter items)
                      (lambda (a b) (string<? (get-name a)
                                              (get-name b)))))

  (set! cover-images '())

  (for-each
    (lambda (item)
      (define item-id (cdr (assoc 'id item)))
      (define cover-event-box (gtk_event_box_new))
      (gtk_widget_set_events cover-event-box GDK_BUTTON_PRESS_MASK)
      (define cover-box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
      (set! cover-images (append! cover-images
                                  `((,item-id . ,cover-box))))
      (gtk_container_add cover-event-box cover-box)
      (gtk_widget_set_size_request cover-box 100 200)
      (define cover (get-cover item))
      (define cached (assoc cover pixbuf-cache))
      (define pixbuf
        (if cover
          (if cached
            (cdr cached)
            (gdk_pixbuf_new_from_file_at_size cover 200 200 #f))
          #f))
      (if (and pixbuf (not cached))
        (set! pixbuf-cache (alist-cons cover pixbuf pixbuf-cache)))

      (define image
        (if pixbuf
          (gtk_image_new_from_pixbuf pixbuf)
          (gtk_image_new_from_icon_name "gtk-missing-image" 1)))

      (gtk_box_pack_start cover-box image 0 1 5)
      (define title-label (gtk_label_new (get-name item)))
      (gtk_label_set_line_wrap title-label 1)
      (gtk_label_set_max_width_chars title-label 18)
      (gtk_box_pack_start cover-box title-label 0 1 5)
      (g_signal_connect cover-event-box "button-press-event"
                        #$cover_button_press
                        (address->pointer item-id))

      (gtk_drag_dest_set
        cover-event-box GTK_DEST_DEFAULT_ALL
        (foreign-value "my_target_table" c-pointer)
        1 GDK_ACTION_COPY)

      (g_signal_connect
        cover-event-box "drag-data-received"
        #$receive_drop_main (address->pointer item-id))

      (gtk_flow_box_insert button-box cover-event-box -1))
    items))

; Poster List helpers

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

(define search-bar #f)

(define button-box #f)

(define cover-images '())

; Settings Scren

(define-external
  (path_picked
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (set! selected-path
    (gtk_file_chooser_get_filename widget))
  ; todo: copy string to scheme then free c string with g_free
  (if (equal? "" (gtk_entry_get_text name-entry))
    (begin
      (define parts (irregex-split "/" selected-path))
      (if (not (null? parts))
        (gtk_entry_set_text name-entry (prettify (last parts))))))
  )
  ;(define dir selected-path)
  ;(if (not (directory? dir))
  ;  (gtk-warn "Your directory doesn't look like a directory")
  ;  (begin
  ;    (define file-list (sort (directory dir #t) string<?))

  ;    (if (not total-entry-changed)
  ;      (begin
  ;        (gtk_entry_set_text
  ;          total-entry
  ;          (number->string
  ;            (do ([n 1 (+ n 1)])
  ;              [(let ([m (find-ep selected-path n #t file-list)])
  ;                 (if m
  ;                   (and (set! file-list
  ;                          (remove (lambda (i) (equal? m i))
  ;                                  file-list))
  ;                        #f)
  ;                   #t))
  ;               (- n 1)])))
  ;        (set! total-entry-changed #f))))))

(define-external
  (save_settings_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define video-player (gtk_entry_get_text video-player-entry))
  (set-default-video-player db video-player)
  (if selected-path
    (set-default-path db selected-path))
  (define autoplay (gtk_toggle_button_get_active autoplay-checkbox))
  (set-autoplay db (= autoplay 1))
  (build-main-screen window))

(define-external
  (go_back
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
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

  (define autoplay (get-autoplay db))
  (set! autoplay-checkbox (gtk_check_button_new_with_label "Autoplay"))
  (gtk_toggle_button_set_active autoplay-checkbox (if autoplay 1 0)) ; shouldn't this be handled by bind?
  (gtk_grid_attach form autoplay-checkbox 0 2 1 1)

  (define button-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define add-button (gtk_button_new_with_label "Save"))
  (define back-button (gtk_button_new_with_label "Cancel"))
  (gtk_box_pack_start button-box add-button 1 1 5)
  (gtk_box_pack_end button-box back-button 1 1 5)

  (gtk_box_pack_end box button-box 0 0 5)

  (g_signal_connect add-button "clicked" #$save_settings_button #f)
  (g_signal_connect back-button "clicked" #$go_back #f)

  (gtk_widget_show_all window))

; View Screen

(define-external
  (remove_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define confirm-dialog (gtk_message_dialog_new_wrap
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
  (print id)
  (build-edit-screen window id))

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

(define-external
  (receive_drop
    ((pointer "GtkWidget") widget)
    (c-pointer context)
    (int x)
    (int y)
    (c-pointer data)
    (unsigned-int info)
    (unsigned-int time)
    (c-pointer user-data))
  void
  ; fixme free the string
  (define dropped-text
    (string-trim-both
      (my_gtk_selection_data_get_text data)))
  (define id (data->id user-data))
  (magic-drop-cover dropped-text id)
  (build-view-screen window id))


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

  (define title-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define title-label (make-title-label (get-name item)))
  (gtk_box_set_center_widget title-box title-label)

  (define remove-button (gtk_button_new_from_icon_name
                          "gtk-remove"
                          GTK_ICON_SIZE_BUTTON))
  (gtk_box_pack_end title-box remove-button 0 1 3)
  (g_signal_connect remove-button "clicked" #$remove_button
                    (address->pointer id))

  (define edit-button (gtk_button_new_from_icon_name
                        "gtk-edit"
                        GTK_ICON_SIZE_BUTTON))
  (gtk_box_pack_end title-box edit-button 0 1 0)
  (g_signal_connect edit-button "clicked" #$edit_button
                    (address->pointer id))

  (gtk_box_pack_start box title-box 0 1 5)

  (define cover (get-cover item))
  (define pixbuf
    (if cover
     (gdk_pixbuf_new_from_file_at_size cover 300 300 #f)
     #f))
  (define image
    (if pixbuf
      (gtk_image_new_from_pixbuf pixbuf)
      (gtk_image_new_from_icon_name "gtk-missing-image" 1)))

  (if pixbuf (g_object_unref pixbuf))

  (define cover-event-box (gtk_event_box_new))

  (gtk_drag_dest_set
    cover-event-box GTK_DEST_DEFAULT_ALL
    (foreign-value "my_target_table" c-pointer)
    1 GDK_ACTION_COPY)

  (g_signal_connect
    cover-event-box "drag-data-received" #$receive_drop
    (address->pointer id))

  (gtk_container_add cover-event-box image)
  (gtk_box_pack_start box cover-event-box 1 1 5)

  (define progress-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))

  (define curr-adj (gtk_adjustment_new
                     (get-curr-ep item) 1 (get-total-eps item) 1 0 0))
  ; FIXME: valgrind calls a memory leak around here
  (set! curr-spin (gtk_spin_button_new curr-adj 0 0))
  (gtk_box_pack_start progress-box curr-spin 0 1 5)
  (g_signal_connect
    curr-spin "value-changed" #$ep_num_changed (address->pointer id))

  (define total-label (gtk_label_new (format #f "/ ~A"
                                             (get-total-eps item))))
  (gtk_box_pack_start progress-box total-label 0 1 5)

  (gtk_box_pack_start box progress-box 1 0 5)

  (gtk_widget_set_halign progress-box GTK_ALIGN_CENTER)

  (define button (gtk_button_new_with_label "Watch"))
  (g_signal_connect button "clicked" #$watch_button
                    (address->pointer id))
  (gtk_box_pack_start box button 0 1 2)
  (define button (gtk_button_new_with_label "Watch Next"))
  (g_signal_connect button "clicked" #$watch_next_button
                    (address->pointer id))
  (gtk_box_pack_start box button 0 1 2)
  (define bbutton (gtk_button_new_with_label "Back"))
  (gtk_widget_set_margin_top bbutton 20)
  (gtk_box_pack_end box bbutton 0 1 2)
  (g_signal_connect bbutton "clicked" #$go_back #f)

  (gtk_widget_show_all window))

; View screen helpers

; neet-like
(define (find-ep dir num #!optional quiet file-list)
  (set! dir (ensure-trailing-slash dir))
  (let ([gtk-warn (if quiet (lambda (s) #f) gtk-warn)])
   (if (not file-list)
     (if (not (directory? dir))
       (gtk-warn "Your directory doesn't look like a directory")
       (set! file-list (sort (directory dir #t) string<?))))
   (if (null? file-list)
     (begin
       (gtk-warn "Can't find any files")
       #f)
     (begin
       ; These are stolen from onodera's neet source
       (define regexes
         (map (lambda (r) (irregex (format #f r num)))
              (list "(e|ep|episode|第)[0 ]*~A[^0-9]"
                    "( |_|-|#|\\.)[0 ]*~A[^0-9]"
                    "(^|[^0-9])[0 ]*~A[^0-9]"
                    "~A[^0-9]")))
       (define all-regexes regexes)

       (define (find-file file-list regexes)
         (if (null? regexes)
           #f
           (let*
            ([r (car regexes)]
             [matches
              (map
                cdr
                (sort
                  (filter
                    car
                    (map (lambda (s) (cons (irregex-search r s) s))
                         file-list))
                  (lambda (a b)
                    (< (irregex-match-start-index (car a))
                       (irregex-match-start-index (car b))))))])
             (if (null? matches)
               (find-file file-list (cdr regexes))
               (car matches)))))
       (define f (find-file file-list regexes))

       (if f
         (format #f "~A~A" dir f)
         (begin
           (gtk-warn "File not found")
           #f))))))

; autoplay counter
; TODO find a better way of passing this data to the callbacks. At least this won't give segfaults.
(define autoplay-callback-data '())

(define-external
  (autoplay_stop_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (define item (get-item db id))
  (define timer (car autoplay-callback-data))
  (define label (cadr autoplay-callback-data))
  (define episode (cadr (cdr autoplay-callback-data)))
  (g_source_remove timer)
  (set! autoplay-callback-data '())
  (set-curr-ep item episode)
  (build-view-screen window id))

(define-external
  (autoplay_count_down
    (c-pointer data))
  bool
  (define id (data->id data))
  (define timer (car autoplay-callback-data))
  (define label (cadr autoplay-callback-data))
  (define episode (cadr (cdr autoplay-callback-data)))
  (define counter (string->number (gtk_label_get_text label)))
  (if (> counter 0)
    (begin
      (gtk_label_set_text label (number->string (- counter 1)))
      #t)
    (begin
      (watch-episode id (+ episode 1))
      (build-view-screen window id)
      #f)))

(define (make-counter-label text)
  (define counter-label (gtk_label_new text))
  ;(gtk_label_set_xalign title-label 0)
  (define counter-attrs (pango_attr_list_new))
  (define attr-weight (pango_attr_weight_new PANGO_WEIGHT_BOLD))
  (pango_attr_list_insert counter-attrs attr-weight)
  (define attr-scale (pango_attr_scale_new 10))
  (pango_attr_list_insert counter-attrs attr-scale)
  (gtk_label_set_attributes counter-label counter-attrs)
  (pango_attr_list_unref counter-attrs)
  counter-label)

(define (build-autoplay-next-episode-screen window id episode)
  (clean window)

  (define item (get-item db id))
  (define ep (get-curr-ep item))
  (define box (gtk_box_new GTK_ORIENTATION_VERTICAL 0))
  (gtk_box_set_spacing box 10)
  (gtk_widget_set_margin_top box 20)
  (gtk_widget_set_margin_start box 20)
  (gtk_widget_set_margin_end box 20)
  (gtk_widget_set_margin_bottom box 20)
  (gtk_container_add window box)

  ;(define title-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define title-label (make-title-label "Playing next on..."))
  ;(gtk_box_set_center_widget title-box title-label)
  (gtk_box_pack_start box title-label 0 0 0)

  (define counter (make-counter-label "5")) ; TODO setting to default time
  (define timer (g_timeout_add_seconds 1 #$autoplay_count_down (address->pointer id)))
  (gtk_box_pack_start box counter 1 0 0)

  (define stop-button (gtk_button_new_with_label "Stop"))
  (g_signal_connect stop-button "clicked" #$autoplay_stop_button (address->pointer id))
  (gtk_box_pack_start box stop-button 0 0 0)

  (set! autoplay-callback-data (list timer counter episode))

  (gtk_widget_show_all window))

(define player-process '())

(define-external
  (player_process_end
    (c-pointer data))
  bool
  (define id (data->id data))
  (define process-id (car player-process))
  (define episode (cadr player-process))
  (define autoplay (get-autoplay db))
  (define item (get-item db id))
  (receive (pid normal status) (process-wait process-id #t)
    (if (and (= pid process-id) ; process-wait will return 0 if the process hasn't finished.
         autoplay)
      (begin
        (if (> (+ episode 1) (get-total-eps item))
          (set-curr-ep item (get-total-eps item)) ; finished series, update total.
          (begin
            (set! player-process '())
            (build-autoplay-next-episode-screen window id episode)))
        #f)
      #t)))

(define (wait-for-player id)
  (g_timeout_add_seconds 1 #$player_process_end (address->pointer id)))

(define (watch-episode id episode)
  (define item (get-item db id))
  (define dir (get-path item))
  (define autoplay (get-autoplay db))
  (define fn (find-ep dir episode))
  (if fn
    (begin
      (printf "watch ~A ~A ~A~%"
              (get-name item) (get-curr-ep item) fn)
      (define video-player (or (get-video-player item)
                              (get-default-video-player db)))
      (define cmd-string
        (append (string-split video-player) (list fn)))
      (define process-id (process-run (car cmd-string) (cdr cmd-string)))
      (if (and autoplay
           (null? player-process))
        (begin
          (set! player-process (list process-id episode))
          (wait-for-player id))))))

(define (watch id)
  (define item (get-item db id))
  (watch-episode id (get-curr-ep item)))

; Add New screen

(define-external
  (add_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define name (gtk_entry_get_text name-entry))
  (define curr (or (string->number (gtk_entry_get_text curr-entry)) 0))
  (define total (or (string->number (gtk_entry_get_text total-entry))
                    (max curr 24)))
  (define video-player (gtk_entry_get_text video-player-entry))
  (define cover selected-image-path)
  (add-item db curr total name
    (or selected-path
        (get-default-path db))
    video-player
    cover)
  ;(build-main-screen window)
  (build-view-screen window (- (length (get-item-list db)) 1)))

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

  (add-edit-buttons form "" (get-default-path db) "1" "24" "" #f)

  (define button-box (gtk_box_new GTK_ORIENTATION_HORIZONTAL 0))
  (define add-button (gtk_button_new_with_label "Add"))
  (define back-button (gtk_button_new_with_label "Cancel"))
  (gtk_box_pack_start button-box add-button 1 1 5)
  (gtk_box_pack_end button-box back-button 1 1 5)

  (gtk_box_pack_end box button-box 0 0 5)

  (g_signal_connect add-button "clicked" #$add_button #f)
  (g_signal_connect back-button "clicked" #$go_back #f)

  (gtk_widget_show_all window))

; Edit Screen

(define-external
  (save_edit_button
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define id (data->id data))
  (define name (gtk_entry_get_text name-entry))
  (define curr (or (string->number (gtk_entry_get_text curr-entry)) 0))
  (define total (or (string->number (gtk_entry_get_text total-entry))
                    (max curr 24)))
  (define video-player (gtk_entry_get_text video-player-entry))
  (define item (get-item db id))
  (set-name item name)
  (if selected-path
    (set-path item selected-path))
  (set-curr-ep item curr)
  (set-total-eps item total)
  (set-video-player item video-player)
  (set-cover item selected-image-path)
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
                    (or (get-video-player item) "")
                    (get-cover item))

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


; add / edit controls

(define-external
  (image_picked
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (set! selected-image-path
    (gtk_file_chooser_get_filename widget)))

(define-external
  (image_download
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (define file-name
    (auto-download-image (gtk_entry_get_text name-entry)))
  (if file-name
    (begin
      (gtk_file_chooser_set_filename image-path-picker file-name)
      (set! selected-image-path file-name))
    (print "couldn't get image"))) ; todo handle this better

(define-external
 (total_entry_changed
   ((pointer "GtkWidget") widget)
   (c-pointer data))
 void
 (set! total-entry-changed #t))

(define (add-edit-buttons form name path curr total video-player cover)
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

  (define image-path-label (gtk_label_new "Cover Image Path:"))
  (gtk_label_set_xalign image-path-label 1)
  ;(set! image-path-entry (gtk_entry_new))
  ;(gtk_entry_set_text image-path-entry "image path here")
  (set! image-path-picker
    (gtk_file_chooser_button_new "Select the cover image"
                                 GTK_FILE_CHOOSER_ACTION_OPEN))
  (if cover
    (begin
      (gtk_file_chooser_set_filename image-path-picker cover)
      (set! selected-image-path cover)))
  (set! selected-path #f)
  (g_signal_connect image-path-picker "file-set" #$image_picked #f)
  (define image-filter (gtk_file_filter_new))
  (gtk_file_filter_add_mime_type image-filter "image/*")
  (gtk_file_filter_set_name image-filter "Image File")
  (gtk_file_chooser_add_filter image-path-picker image-filter)
  (gtk_widget_set_hexpand image-path-picker 1)
  (define fetch-image-button (gtk_button_new_with_label "Download"))
  (g_signal_connect fetch-image-button "clicked" #$image_download #f)
  (gtk_grid_attach form image-path-label 0 2 1 1)
  (gtk_grid_attach form image-path-picker 1 2 2 1)
  (gtk_grid_attach form fetch-image-button 3 2 1 1)

  (define eps-label (gtk_label_new "Current Episode:"))
  (gtk_label_set_xalign eps-label 1)
  (set! curr-entry (gtk_entry_new))
  (gtk_entry_set_text curr-entry curr)
  (gtk_widget_set_hexpand curr-entry 1)
  (define eps-slash (gtk_label_new "/"))
  (set! total-entry (gtk_entry_new))
  (g_signal_connect total-entry "changed" #$total_entry_changed #f)
  (gtk_entry_set_text total-entry total)
  (set! total-entry-changed #f)
  (gtk_widget_set_hexpand total-entry 1)
  (gtk_grid_attach form eps-label 0 3 1 1)
  (gtk_grid_attach form curr-entry 1 3 1 1)
  (gtk_grid_attach form eps-slash 2 3 1 1)
  (gtk_grid_attach form total-entry 3 3 1 1)

  (define video-player-label (gtk_label_new "Video Player:"))
  (gtk_label_set_xalign video-player-label 1)
  (set! video-player-entry (gtk_entry_new))
  (gtk_entry_set_text video-player-entry video-player)
  (gtk_widget_set_hexpand video-player-entry 1)
  (gtk_grid_attach form video-player-label 0 4 1 1)
  (gtk_grid_attach form video-player-entry 1 4 3 1))

; add / edit helpers

(define name-entry #f)
(define selected-path #f)
(define selected-image-path #f)
(define image-path-picker #f)

(define curr-entry #f)
(define total-entry #f)
(define total-entry-changed #f)
(define video-player-entry #f)

(define (prettify name)
  (string-titlecase
    (let ((name (irregex-replace/all "\\[.*\\]" name "")))
      (set! name
        (irregex-replace/all "_|-|\\.|[[:space:]]" name " "))
      (irregex-replace/all " +" name " "))))

; The Movie DB

(define tmdb "https://api.themoviedb.org/3/")
(define tmdb-key "api_key=fd7b3b3e7939e8eb7c8e26836b8ea410")
(define base-url #f)

(define (get-extension fn)
  (define m (irregex-search "\\..*" (irregex-replace ".*/" fn "")))
  (if m (irregex-match-substring m) ""))

(define (clean-name name) ; for tmdb search
  (string-trim-both (irregex-replace/all "\\(.*\\)|/" name "")))

(define (download-image image-url file-name)
  (print "downloading...")
  (call-with-input-request
    image-url #f
    (lambda (rport)
      (call-with-output-file
        file-name
        (lambda (wport)
          (do ((byte (read-byte rport) (read-byte rport)))
            ((eof-object? byte) #f)
            (write-byte byte wport))))))
  (print "downloaded!"))

(define (auto-download-image dirty-name)
  (define name (uri-encode-string (clean-name dirty-name)))
  (define file-name (format #f "~A~A" xdg-data name)) ;missing ext
  (print name)
  (define url (format #f "~Asearch/multi?query=~A&~A"
                      tmdb name tmdb-key))
  (print url)
  (define response
    (condition-case
      (read-json (with-input-from-request url #f read-string))
      [e (exn http) (begin
                   (gtk-warn "HTTP error")
                   (print e)
                   '((results . #())))]))
  ;(print response)
  (define results (cdr (assoc 'results response)))
  (if (= 0 (vector-length results))
    #f ; todo error out
    (begin
      (define result (vector-ref results 0))
      (define poster-path (cdr (assoc 'poster_path result)))
      (if (not base-url)
        (begin
          (define url (format #f "~Aconfiguration?~A"
                              tmdb tmdb-key))
          (define config
            (read-json
              (with-input-from-request url #f read-string)))
          (set! base-url
            (cdr (assoc 'base_url (cdr (assoc 'images config)))))))
      (if (or (null? poster-path) (eqv? 'null poster-path))
        (and
          (gtk-warn "Couldn't find the poster in tmdb's response")
          #f)
        (begin
          (define image-url (format #f "~Aoriginal~A"
                                    base-url poster-path))
          (print image-url)
          (set! file-name (format #f "~A~A" file-name
                                  (get-extension poster-path)))
          (print file-name)
          (download-image image-url file-name)
          file-name)))))

; Drag & Drop

(foreign-declare
  "static GtkTargetEntry my_target_table[] = {{ \"text/plain\", 0, 0 }};")

(define (get-g-string* ptr)
  ; we pass the pointer through here to get a chicken string
  ; just like calling ##sys#peek-c-string, but without undocumented stuff
  (define g-string-passtrough
    (foreign-lambda* c-string ((c-pointer p))
      "C_return(p);"))
  (define managed-string (g-string-passtrough ptr))
  ;(define managed-string (##sys#peek-c-string ptr '0))
  (g_free ptr)
  managed-string)

; we can't use bind generated definitions because they don't call g_free
(define (my_gtk_selection_data_get_text selection)
  (get-g-string*
    ((foreign-lambda c-pointer
                     "gtk_selection_data_get_text"
                     c-pointer) selection)))

(define (my_gtk_file_chooser_get_filename widget)
  (get-g-string*
    ((foreign-lambda c-pointer
                     "gtk_file_chooser_get_filename"
                     c-pointer) widget)))

; note that gtk_entry_get_text doesn't return a copy, so we must not
; call g_free on it's returned pointer

(define (magic-drop-cover uri id)
  (define item (get-item db id))
  (print item)
  (printf "text ~S~%" uri)
  (define protocol-match
    (irregex-search "^(.*)://(.*)" uri))
  (if protocol-match
    (begin
      (define protocol-name (irregex-match-substring
                              protocol-match 1))
      (printf "protocol ~A~%" protocol-name)
      (if (equal? protocol-name "file")
        (begin
          ;todo maybe copy to xdg_data?
          (define path (irregex-match-substring
                         protocol-match 2))
          (set-cover item (uri-decode-string path))
          (printf "path ~A~%" path)))
      (if (or (equal? protocol-name "http")
              (equal? protocol-name "https"))
        (begin
          (define url uri)
          (printf "url ~A~%" url)
          (define file-name (format #f "~A~A~A"
                                    xdg-data
                                    (clean-name (get-name item))
                                    (get-extension url)))
          (download-image url file-name)
          (set-cover item file-name))))))

(define (update-cover-main-screen id)
  (print id)
  (define item (get-item db id))
  (define cover-box (cdr (assoc id cover-images)))
  (clean-container cover-box)

  (define cover (get-cover item))
  (define pixbuf
     (if cover
       (gdk_pixbuf_new_from_file_at_size cover 200 200 #f)
       #f))
  (define image
     (if pixbuf
       (gtk_image_new_from_pixbuf pixbuf)
       (gtk_image_new_from_icon_name "gtk-missing-image" 1)))
  (if pixbuf (g_object_unref pixbuf))
  (gtk_box_pack_start cover-box image 1 1 5)
  (define title-label (gtk_label_new (get-name item)))
  (gtk_label_set_line_wrap title-label 1)
  (gtk_label_set_max_width_chars title-label 18)
  (gtk_box_pack_start cover-box title-label 0 1 5)

  (gtk_widget_show_all window)
  #f)

; Gtk entry & exit points

(define-external
  (destroy
    ((pointer "GtkWidget") widget)
    (c-pointer data))
  void
  (gtk_main_quit))

(define (gtk-warn message)
  (define dialog (gtk_message_dialog_new_wrap
                  window
                  0
                  GTK_MESSAGE_WARNING
                  GTK_BUTTONS_OK
                  message))
  (gtk_dialog_run dialog)
  (gtk_widget_destroy dialog))

(gtk_init #f #f)
(define window (gtk_window_new GTK_WINDOW_TOPLEVEL))
(condition-case (load-db)
  [(exn file i/o) (gtk-warn "Couldn't load the database file; using sample")])
(g_signal_connect window "destroy" #$destroy #f)
;(gtk_window_set_type_hint window GDK_WINDOW_TYPE_HINT_DIALOG)
(gtk_window_set_title window app-title)
(gtk_window_set_default_size window 570 600)
(build-main-screen window)

(gtk_main)

(save-db)
