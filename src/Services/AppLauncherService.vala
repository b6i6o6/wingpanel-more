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
//

namespace Wingpanel {

    [DBus (name = "org.pantheon.desktop.AppLauncherService")]
    private interface AppLauncherIface : Object {
        public signal void visibility_changed (bool launcher_visible);
    }

    public class AppLauncherService : Object {
        const string SERVICE_NAME = "org.pantheon.desktop.AppLauncherService";
        const string SERVICE_PATH = "/org/pantheon/desktop/AppLauncherService";

        public signal void launcher_state_changed (bool active);
        public bool launcher_active { get; private set; default = false; }

        private bool connected = false;
        private AppLauncherIface? launcher_proxy = null;
        uint watch = -1;

        private Settings settings;

        public AppLauncherService (Settings settings) {
            this.settings = settings;

            // Add watch
            watch = Bus.watch_name (BusType.SESSION,
                                    SERVICE_NAME,
                                    BusNameWatcherFlags.NONE,
                                    on_name_appeared,
                                    on_name_vanished);
        }

        private void on_name_appeared (DBusConnection conn, string name) {
            connect_to_server ();
        }

        private void on_name_vanished (DBusConnection conn, string name) {
            disconnect_server ();
            launcher_state_changed (false);
        }

        public void launch_launcher () {
            if (!spawn_launcher_process ())
                return;

            if (!connected)
                connect_to_server ();
        }

        private bool spawn_launcher_process () {
            debug ("Starting launcher!");

            // Parse Arguments
            string[] argvp = null;
            string launcher_command = settings.default_launcher;

            try {
                Shell.parse_argv (launcher_command, out argvp);
            }
            catch (ShellError error) {
                warning ("Not passing any args to %s : %s", launcher_command, error.message);
                argvp = {launcher_command, null}; // fix value in case it's corrupted
            }

            // Check if the program is actually there
            string? launcher = Environment.find_program_in_path (argvp[0]);
            if (launcher != null) {
                // Spawn process asynchronously
                try {
                    var flags =  SpawnFlags.SEARCH_PATH |
                                 SpawnFlags.DO_NOT_REAP_CHILD |
                                 SpawnFlags.STDOUT_TO_DEV_NULL;
                    Pid process_id;
                    Process.spawn_async (null, argvp, null, flags, null, out process_id);
                    // Add watch or otherwise the process will become a zombie
                    ChildWatch.add (process_id, (pid, status) => {
                        Process.close_pid (pid);
                    });
                }
                catch (SpawnError err) {
                    warning ("Couldn't spawn launcher: %s", err.message);
                    return_val_if_reached (false);
                }
            } else {
                Granite.Services.System.open_uri ("file:///usr/share/applications");
            }

            return true;
        }

        private bool connect_to_server () {
            if (connected)
                return true;

            // Connect to the server
            if (launcher_proxy == null) {
                try {
                    launcher_proxy = Bus.get_proxy_sync (BusType.SESSION, SERVICE_NAME, SERVICE_PATH);
                } catch (IOError e) {
                    critical ("Could not connect to AppLauncherService: %s", e.message);
                    launcher_proxy = null;
                    return_val_if_reached (false);
                }
            }

            connected = true;

            debug ("Connected to AppLauncherService");

            // Connect signal handler
            launcher_proxy.visibility_changed.connect (on_launcher_visibility_change);

            return true;
        }

        private void disconnect_server () {
            connected = false;
            launcher_proxy = null;
        }

        private void on_launcher_visibility_change (AppLauncherIface proxy, bool visible) {
            return_if_fail (connected);

            this.launcher_active = visible;
            this.launcher_state_changed (visible);
        }
    }
}
