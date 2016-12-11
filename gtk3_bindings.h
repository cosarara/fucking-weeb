typedef enum
{
  G_APPLICATION_FLAGS_NONE,
  G_APPLICATION_IS_SERVICE  =          1,
  G_APPLICATION_IS_LAUNCHER =          2,

  G_APPLICATION_HANDLES_OPEN =         4,
  G_APPLICATION_HANDLES_COMMAND_LINE = 8,
  G_APPLICATION_SEND_ENVIRONMENT    =  16,

  G_APPLICATION_NON_UNIQUE =           32,

  G_APPLICATION_CAN_OVERRIDE_APP_ID =  64
} GApplicationFlags;

typedef enum
{
  GDK_WINDOW_TYPE_HINT_NORMAL,
  GDK_WINDOW_TYPE_HINT_DIALOG,
  GDK_WINDOW_TYPE_HINT_MENU,		/* Torn off menu */
  GDK_WINDOW_TYPE_HINT_TOOLBAR,
  GDK_WINDOW_TYPE_HINT_SPLASHSCREEN,
  GDK_WINDOW_TYPE_HINT_UTILITY,
  GDK_WINDOW_TYPE_HINT_DOCK,
  GDK_WINDOW_TYPE_HINT_DESKTOP,
  GDK_WINDOW_TYPE_HINT_DROPDOWN_MENU,	/* A drop down menu (from a menubar) */
  GDK_WINDOW_TYPE_HINT_POPUP_MENU,	/* A popup menu (from right-click) */
  GDK_WINDOW_TYPE_HINT_TOOLTIP,
  GDK_WINDOW_TYPE_HINT_NOTIFICATION,
  GDK_WINDOW_TYPE_HINT_COMBO,
  GDK_WINDOW_TYPE_HINT_DND
} GdkWindowTypeHint;

typedef enum
{
  GTK_ORIENTATION_HORIZONTAL,
  GTK_ORIENTATION_VERTICAL
} GtkOrientation;

typedef enum
{
  GTK_BUTTONBOX_SPREAD = 1,
  GTK_BUTTONBOX_EDGE,
  GTK_BUTTONBOX_START,
  GTK_BUTTONBOX_END,
  GTK_BUTTONBOX_CENTER,
  GTK_BUTTONBOX_EXPAND
} GtkButtonBoxStyle;

typedef char   gchar;
typedef short  gshort;
typedef long   glong;
typedef int    gint;
typedef gint   gboolean;

typedef unsigned char   guchar;
typedef unsigned short  gushort;
typedef unsigned long   gulong;
typedef unsigned int    guint;

typedef float   gfloat;
typedef double  gdouble;

GtkApplication* gtk_application_new
(const gchar *application_id, GApplicationFlags flags);

int g_signal_connect(void *, char *, void *, void *);
int g_signal_connect_swapped(void *, char *, void *, void *);

___safe int g_application_run
(GApplication *application, int argc, char **argv);

GtkWidget* gtk_application_window_new
(GtkApplication* application);

void gtk_widget_show_all (GtkWidget* widget);

void gtk_window_set_type_hint
(GtkWindow* window, GdkWindowTypeHint hint);

GtkWidget *
gtk_button_box_new (GtkOrientation orientation);

void
gtk_button_box_set_layout (GtkButtonBox *widget,
                           GtkButtonBoxStyle layout_style);

void
gtk_container_add (GtkContainer *container,
                   GtkWidget *widget);

GtkWidget *
gtk_button_new_with_label (const gchar *label);

void
gtk_window_set_title (GtkWindow *window,
                      const gchar *title);

void
gtk_window_set_default_size (GtkWindow *window,
                             gint width,
                             gint height);

GtkWidget *
gtk_bin_get_child (GtkBin *bin);

void
gtk_widget_destroy (GtkWidget *widget);

GtkWidget *
gtk_box_new (GtkOrientation orientation,
             gint spacing);

void
gtk_box_pack_start (GtkBox *box,
                    GtkWidget *child,
                    gboolean expand,
                    gboolean fill,
                    guint padding);

void
gtk_box_pack_end (GtkBox *box,
                  GtkWidget *child,
                  gboolean expand,
                  gboolean fill,
                  guint padding);

GtkWidget *
gtk_label_new (const gchar *str);

void
gtk_box_set_spacing (GtkBox *box,
                     gint spacing);

void
gtk_widget_set_margin_start (GtkWidget *widget,
                             gint margin);

void
gtk_widget_set_margin_end (GtkWidget *widget,
                           gint margin);

void
gtk_widget_set_margin_top (GtkWidget *widget,
                           gint margin);

void
gtk_widget_set_margin_bottom (GtkWidget *widget,
                           gint margin);

GtkAdjustment *
gtk_adjustment_new (gdouble value,
                    gdouble lower,
                    gdouble upper,
                    gdouble step_increment,
                    gdouble page_increment,
                    gdouble page_size);

GtkWidget *
gtk_spin_button_new (GtkAdjustment *adjustment,
                     gdouble climb_rate,
                     guint digits);

gint
gtk_spin_button_get_value_as_int (GtkSpinButton *spin_button);

GtkWidget *
gtk_entry_new (void);

GtkWidget *
gtk_grid_new (void);

void
gtk_grid_attach (GtkGrid *grid,
                 GtkWidget *child,
                 gint left,
                 gint top,
                 gint width,
                 gint height);

void
gtk_widget_set_hexpand (GtkWidget *widget,
                        gboolean expand);

void
gtk_widget_set_vexpand (GtkWidget *widget,
                        gboolean expand);

void
gtk_grid_set_column_spacing (GtkGrid *grid,
                             guint spacing);

void
gtk_grid_set_row_spacing (GtkGrid *grid,
                          guint spacing);

void
gtk_label_set_xalign (GtkLabel *label,
                      gfloat xalign);

void
gtk_label_set_yalign (GtkLabel *label,
                      gfloat yalign);

void
gtk_entry_set_text (GtkEntry *entry,
                    const gchar *text);

const gchar *
gtk_entry_get_text (GtkEntry *entry);

typedef enum
{
  GTK_ICON_SIZE_INVALID,
  GTK_ICON_SIZE_MENU,
  GTK_ICON_SIZE_SMALL_TOOLBAR,
  GTK_ICON_SIZE_LARGE_TOOLBAR,
  GTK_ICON_SIZE_BUTTON,
  GTK_ICON_SIZE_DND,
  GTK_ICON_SIZE_DIALOG
} GtkIconSize;

GtkWidget *
gtk_button_new_from_icon_name (const gchar *icon_name,
                               GtkIconSize size);

void
gtk_label_set_attributes (GtkLabel *label,
                          PangoAttrList *attrs);

typedef enum
{
  GTK_ALIGN_FILL,
  GTK_ALIGN_START,
  GTK_ALIGN_END,
  GTK_ALIGN_CENTER,
  GTK_ALIGN_BASELINE
} GtkAlign;

void
gtk_widget_set_halign (GtkWidget *widget,
                       GtkAlign align);

void
gtk_widget_set_valign (GtkWidget *widget,
                       GtkAlign align);

typedef enum
{
  GTK_BUTTONS_NONE,
  GTK_BUTTONS_OK,
  GTK_BUTTONS_CLOSE,
  GTK_BUTTONS_CANCEL,
  GTK_BUTTONS_YES_NO,
  GTK_BUTTONS_OK_CANCEL
} GtkButtonsType;

typedef enum
{
  GTK_DIALOG_MODAL               = 1,
  GTK_DIALOG_DESTROY_WITH_PARENT = 2,
  GTK_DIALOG_USE_HEADER_BAR      = 4
} GtkDialogFlags;

typedef enum
{
  GTK_MESSAGE_INFO,
  GTK_MESSAGE_WARNING,
  GTK_MESSAGE_QUESTION,
  GTK_MESSAGE_ERROR,
  GTK_MESSAGE_OTHER
} GtkMessageType;

// let's pretend it's not variadic
GtkWidget* gtk_message_dialog_new
    (GtkWindow      *parent,
     GtkDialogFlags  flags,
     GtkMessageType  type,
     GtkButtonsType  buttons,
     const gchar    *message_format);

gint
gtk_dialog_run (GtkDialog *dialog);

typedef enum
{
  GTK_RESPONSE_NONE         = -1,
  GTK_RESPONSE_REJECT       = -2,
  GTK_RESPONSE_ACCEPT       = -3,
  GTK_RESPONSE_DELETE_EVENT = -4,
  GTK_RESPONSE_OK           = -5,
  GTK_RESPONSE_CANCEL       = -6,
  GTK_RESPONSE_CLOSE        = -7,
  GTK_RESPONSE_YES          = -8,
  GTK_RESPONSE_NO           = -9,
  GTK_RESPONSE_APPLY        = -10,
  GTK_RESPONSE_HELP         = -11
} GtkResponseType;

typedef enum
{
  GTK_FILE_CHOOSER_ACTION_OPEN,
  GTK_FILE_CHOOSER_ACTION_SAVE,
  GTK_FILE_CHOOSER_ACTION_SELECT_FOLDER,
  GTK_FILE_CHOOSER_ACTION_CREATE_FOLDER
} GtkFileChooserAction;

GtkWidget *
gtk_file_chooser_button_new (const gchar *title,
                             GtkFileChooserAction action);

gchar *
gtk_file_chooser_get_filename (GtkFileChooser *chooser);

gboolean
gtk_file_chooser_set_filename (GtkFileChooser *chooser,
                               const char *filename);

gchar *
gtk_file_chooser_get_uri (GtkFileChooser *chooser);

gboolean
gtk_file_chooser_set_uri (GtkFileChooser *chooser,
                          const char *uri);

// pango

void
pango_attr_list_unref (PangoAttrList *list);

typedef enum {
  PANGO_WEIGHT_THIN = 100,
  PANGO_WEIGHT_ULTRALIGHT = 200,
  PANGO_WEIGHT_LIGHT = 300,
  PANGO_WEIGHT_SEMILIGHT = 350,
  PANGO_WEIGHT_BOOK = 380,
  PANGO_WEIGHT_NORMAL = 400,
  PANGO_WEIGHT_MEDIUM = 500,
  PANGO_WEIGHT_SEMIBOLD = 600,
  PANGO_WEIGHT_BOLD = 700,
  PANGO_WEIGHT_ULTRABOLD = 800,
  PANGO_WEIGHT_HEAVY = 900,
  PANGO_WEIGHT_ULTRAHEAVY = 1000
} PangoWeight;

PangoAttribute *
pango_attr_weight_new (PangoWeight weight);

PangoAttribute *
pango_attr_scale_new (double scale_factor);

void
pango_attribute_destroy (PangoAttribute *attr);

void
pango_attr_list_insert (PangoAttrList *list,
                        PangoAttribute *attr);

PangoAttrList *
pango_attr_list_new (void);

void g_object_unref (void*);
