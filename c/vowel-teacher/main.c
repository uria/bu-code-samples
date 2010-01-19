/* 
 * File:   main.c
 * Author: beni
 *
 * Created on 15 January 2010, 10:16
 *   gcc -o tut tut.c $(pkg-config --cflags --libs gtk+-2.0 gmodule-2.0)
 */
#include <gtk/gtk.h>
#include <math.h>
#include <malloc.h>
#include <stdio.h>
#include <sndfile.h>
#include "recording.h"

static recording *rec;

#define PIXELS_PER_SECOND 100
static GdkPixmap *signal_pixmap = NULL;

void adapt_drawing_to_recording(GdkPixmap **pixmap, GtkWidget *drawing_area, recording *rec) {
    unsigned int total_width;

    total_width = 1 + PIXELS_PER_SECOND * rec->samples_number / rec->sample_rate;

    if (*pixmap)
        gdk_pixmap_unref(*pixmap);

    gtk_widget_set_size_request(drawing_area, total_width, -1);

    *pixmap = gdk_pixmap_new(drawing_area->window,
            total_width,
            drawing_area->allocation.height,
            -1);

    gdk_draw_rectangle(*pixmap,
            drawing_area->style->white_gc,
            TRUE,
            0, 0,
            total_width,
            drawing_area->allocation.height);
}

void draw_signal(GdkPixmap *pixmap, GtkWidget *drawing_area, recording *rec) {
    unsigned int dr_width, dr_half_height;
    unsigned int spp; /* samples per pixel */
    unsigned int i;
    extrema ext;

    dr_width = drawing_area->allocation.width;
    dr_half_height = drawing_area->allocation.height / 2;
    spp = floor((float) rec->samples_number / dr_width);

    for (i = 0; i < dr_width; i++) {
        recording_slot_extrema(rec, i*spp, spp, &ext);
        gdk_draw_line(pixmap, drawing_area->style->fg_gc[GTK_WIDGET_STATE(drawing_area)],
                i, dr_half_height + ext.minimum * dr_half_height,
                i, dr_half_height + ext.maximum * dr_half_height);
    }
}

gboolean configure_event_callback(GtkWidget *widget, GdkEventExpose *event, gpointer data) {
    adapt_drawing_to_recording(&signal_pixmap, widget, rec);
    draw_signal(signal_pixmap, widget, rec);
    return TRUE;
}

gboolean expose_event_callback(GtkWidget *widget, GdkEventExpose *event, gpointer data) {
    gdk_draw_pixmap(widget->window,
            widget->style->fg_gc[GTK_WIDGET_STATE(widget)],
            signal_pixmap,
            event->area.x, event->area.y,
            event->area.x, event->area.y,
            event->area.width, event->area.height);

    return TRUE;
}

int main(int argc, char **argv) {
    GtkBuilder *builder;
    GtkWidget *window;
    GError *error = NULL;
    int err;

    GtkWidget *da;

    /* Init GTK+ */
    gtk_init(&argc, &argv);

    /* Create new GtkBuilder object */
    builder = gtk_builder_new();
    /* Load UI from file. If error occurs, report it and quit application.
     * Replace "tut.glade" with your saved project. */

    if (!gtk_builder_add_from_file(builder, "drawing.glade", &error)) {
        g_warning("%s", error->message);
        g_free(error);
        return ( 1);
    }
    /* Get main window pointer from UI */
    window = GTK_WIDGET(gtk_builder_get_object(builder, "main_window"));

    da = GTK_WIDGET(gtk_builder_get_object(builder, "signal_display"));
    /* Connect signals */
    gtk_builder_connect_signals(builder, NULL);

    /* Destroy builder, since we don't need it anymore */
    g_object_unref(G_OBJECT(builder));

    /* Show window. All other widgets are automatically shown by GtkBuilder */
    gtk_widget_show_all(window);

    err = recording_new_from_file("/home/beni/icelanders.wav", &rec);

    adapt_drawing_to_recording(&signal_pixmap, da, rec);
    draw_signal(signal_pixmap, da, rec);

    g_signal_connect(G_OBJECT(da), "expose_event",
            G_CALLBACK(expose_event_callback), NULL);

    g_signal_connect(G_OBJECT(da), "configure_event",
            G_CALLBACK(configure_event_callback), NULL);


    /* Start main loop */
    gtk_main();

    return ( 0);
}