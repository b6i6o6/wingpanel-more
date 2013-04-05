// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2011-2012 Wingpanel Developers
// 
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
// 
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
// 
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.

public class PanelShadow : Granite.Widgets.CompositedWindow {
    public PanelShadow () {
        skip_taskbar_hint = true; // no taskbar

        var style_context = get_style_context ();
        style_context.add_class ("shadow");

        set_type_hint (Gdk.WindowTypeHint.DOCK);
        set_keep_below (true);
        stick ();
    }

    protected override bool draw (Cairo.Context cr) {
        Gtk.Allocation size;
        get_allocation (out size);

        get_style_context ().render_background (cr, size.x, size.y, size.width, size.height);

        return true;
    }
}
