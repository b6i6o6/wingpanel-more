// -*- Mode: vala; indent-tabs-mode: nil; tab-width: 4 -*-
//  
//  Copyright (C) 2013 Wingpanel Developers
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

namespace Wingpanel.Services {
    public class BackgroundManager {
    
        const int HEIGHT = 20;
        const double MIN_ALPHA = 0.7;
        const double MIN_VARIANCE = 50;
        const double MIN_LUM = 25;
        
        GLib.Settings background_settings;
        string image_location;
        Services.Settings settings;
        
        public BackgroundManager (Services.Settings settings) {
            this.settings = settings;
            
            background_settings = new GLib.Settings ("org.gnome.desktop.background");
            
            background_settings.changed["picture-uri"].connect ((key) => {
                image_location = background_settings.get_string ("picture-uri");
                
                if (settings.auto_adjust_alpha)
                	settings.background_alpha = calculate_alpha ();
            });
            
            background_settings.changed ("picture-uri");
        }
        
        private double calculate_alpha () {
            double alpha = 0;
            
            try {
                var img_buf = new Gdk.Pixbuf.from_file(image_location.substring (5));
                uint8 *pixels = img_buf.get_pixels();

                int width = img_buf.get_width();
                int height = img_buf.get_height();
                
                if (height > HEIGHT)
	                height = HEIGHT;

                int size = width * height;

                double mean = 0;
                double mean_squares = 0;

                double pixel = 0;
                int imax = size * 3;

                for (int i = 0; i < imax; i += 3) {
	                pixel = (0.3 * (double) pixels[i] +
			                 0.6 * (double) pixels[i + 1] +
			                 0.11 * (double) pixels[i + 2]) - 128f;

	                mean += pixel;
	                mean_squares += pixel * pixel;
                }

                mean /= size;
                mean_squares *= mean_squares / size;

                double variance = Math.sqrt(mean_squares - mean * mean) / (double) size;

                if (mean > MIN_LUM || variance > MIN_VARIANCE)
	                alpha = MIN_ALPHA;
            }
            catch {
                alpha = MIN_ALPHA;
            }
            
            return alpha;
        }
    }
}
