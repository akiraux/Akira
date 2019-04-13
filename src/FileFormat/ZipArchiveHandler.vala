/*
 *  Copyright (C) 2019 Felipe Escoto <felescoto95@hotmail.com>
 *
 *  This program or library is free software; you can redistribute it
 *  and/or modify it under the terms of the GNU Lesser General Public
 *  License as published by the Free Software Foundation; either
 *  version 3 of the License, or (at your option) any later version.
 *
 *  This library is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 *  Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General
 *  Public License along with this library; if not, write to the
 *  Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 *  Boston, MA 02110-1301 USA.
 */

public class Akira.FileFormat.ZipArchiveHandler : GLib.Object {

    // Prefix to be added at the beginning of the folder name when a gzipped file is opened. Should start with a period to hide the folder by default
    private const string UNARCHIVED_PREFIX = ".~lock.akira.";

    /**
     * The GZipped File that opened this archive
     */
    public File opened_file { get; construct set; }

    /**
     * The Unzipped folder location
     */
    public File unarchived_location { get; private set; }

    /**
     * Creates a zipped file for archive purposes
     */
    public ZipArchiveHandler (File gzipped_file) {
        Object (opened_file: gzipped_file.dup ());
    }

    public FileCollector file_collector { get; private set; }

    construct {
        var parent_folder = opened_file.get_parent ().get_path ();
        unarchived_location = File.new_for_path (Path.build_filename (parent_folder, UNARCHIVED_PREFIX + opened_file.get_basename ()));

        file_collector = new FileCollector (unarchived_location);
    }


    protected static string get_content_from_file (File file) {
        try {
            string data;
            FileUtils.get_contents (file.get_path (), out data);

            return data;
        } catch (Error e) {
            warning (e.message);
            return "";
        }
    }

    protected static Json.Object get_content_as_json (File file) {
        try {
            var parser = new Json.Parser ();
            parser.load_from_data (get_content_from_file (file));

            return parser.get_root ().get_object ();
        } catch (Error e) {
            return new Json.Object ();
        }
    }

    protected static void write_content_to_file (File file, string data) {
        try {
            FileUtils.set_contents (file.get_path (), data);
        } catch (Error e) {
            warning (e.message);
        }
    }

    /**
     * Helper function to create a directory if it does not exist
     */
    protected void make_dir (File file) {
        if (!file.query_exists ()) {
            try {
                file.make_directory_with_parents ();
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }
    }

    /**
     * Helper function to create a file if it does not exist
     */
    protected void make_file (File file) {
        if (!file.query_exists ()) {
            try {
                file.create (FileCreateFlags.REPLACE_DESTINATION);
            } catch (Error e) {
                warning ("%s\n", e.message);
            }
        }
    }

    /**
     * Used to create all the files needed for this if they do not exist.
     *
     * Can be overwritten to add your own files and folders for the internal
     * file structure you require. If overwritten, make sure to call base.prepare ()
     */
    public virtual void prepare () {
        var parent_folder = opened_file.get_parent ();
        make_dir (parent_folder);
        make_file (opened_file);
        make_dir (unarchived_location);
    }

    /**
     * Used to check if the file was already extracted. Use this to handle recovery for your users.
     */
    protected virtual bool is_opened () {
        return unarchived_location.query_exists ();
    }

    /**
     * Extracts the contents of the file to unarchived_location
     */
    protected void open_archive () throws Error {
        extract (opened_file, unarchived_location);
    }

    /**
     * Saves content from the unzipped location to the GZipped file.
     */
    protected void write_to_archive () throws Error {
        // Clear files marked before archiving anything
        file_collector.delete_files_marked_for_deletion ();

        // Saving to a temp file first to avoid dataloss on a crash

        var tmp_file = File.new_for_path (opened_file.get_path () + ".tmp");

        compress (unarchived_location, tmp_file);
        if (opened_file.query_exists ()) {
            opened_file.delete ();
        }

        FileUtils.rename (tmp_file.get_path (), opened_file.get_path ());
    }

    /**
     * Removes all files from the unarchived location. Should run before closing the program to cleanup temp files
     */
    protected void clean () throws Error {
        // Checking if it contains the prefix as a safety to prevent errors
        if (is_opened () && unarchived_location.get_path ().contains (UNARCHIVED_PREFIX)) {
            delete_recursive (unarchived_location);
            unarchived_location.delete ();
        }
    }

    public File get_file_from_basename (File location, string basename) {
        var path = Path.build_filename (location.get_path (), basename);
        return File.new_for_path (path);
    }

    /**
     * Get's a random file inside the archive at the location specified
     * using a guid-like name.
     *
     * @param location Location inside of the archive where the file will live at.
     *
     * @param extension The extension the file created will have
     *
     * @param format The format for the file. The character "?" will be replaced
     * with a random character. For example, XXXX-XX can become a5b7-Df.
     * The default is "XXXXXXXX-XXXX-XX"
     */
    public File get_random_file_name (File location, string extension, string format = "XXXXXXXX-XXXX-XX") {
        do {
            var path = Path.build_filename (location.get_path (), get_guid (format) + "." + extension);

            var file = File.new_for_path (path);
            if (!file.query_exists ()) {
                return file;
            }
        } while (true);
    }

    private Rand? rand = new Rand ();
    private const string GUID_CHARS = "0123456789ABCDEFabcdef";

    private string get_guid (string format) {
        var guid = new StringBuilder.sized (format.length);
        int format_length = format.length;

        for (int i = 0; i < format_length; i++) {
            switch (format[i]) {
                case 'X':
                    var r = rand.next_int () % GUID_CHARS.length;
                    guid.append_c (GUID_CHARS[r]);
                    break;
                default:
                    guid.append_c (format[i]);
                    break;
            }
        }

        return guid.str;
    }

    // DANGEROUS, use with caution
    private void delete_recursive (File file) {
        try {
            var enumerator = file.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo file_info;
            while ((file_info = enumerator.next_file ()) != null) {
                var current_file = file.resolve_relative_path (file_info.get_name ());

                if (file_info.get_file_type () == FileType.DIRECTORY) {
                    delete_recursive (current_file);
                }

                current_file.delete ();
            }
        } catch (Error e) {
            critical ("Error: %s\n", e.message);
        }
    }

    // Extracts all contents of the gzip file to the location
    private static void extract (File gzipped_file, File location) throws Error {
        Archive.ExtractFlags flags;
        flags = Archive.ExtractFlags.TIME;
        flags |= Archive.ExtractFlags.PERM;
        flags |= Archive.ExtractFlags.ACL;
        flags |= Archive.ExtractFlags.FFLAGS;

        Archive.Read archive = new Archive.Read ();
        archive.support_format_all ();
        archive.support_filter_all ();

        Archive.WriteDisk extractor = new Archive.WriteDisk ();
        extractor.set_options (flags);
        extractor.set_standard_lookup ();

        if (archive.open_filename (gzipped_file.get_path (), 10240) != Archive.Result.OK) {
            throw new FileError.FAILED ("Error opening %s: %s (%d)", gzipped_file.get_path (), archive.error_string (), archive.errno ());
        }

        unowned Archive.Entry entry;
        Archive.Result last_result;
        while ((last_result = archive.next_header (out entry)) == Archive.Result.OK) {
            entry.set_pathname (Path.build_filename (location.get_path (), entry.pathname ()));

            if (extractor.write_header (entry) != Archive.Result.OK) {
                continue;
            }

            void* buffer = null;
            size_t buffer_length;
            Posix.off_t offset;
            while (archive.read_data_block (out buffer, out buffer_length, out offset) == Archive.Result.OK) {
                if (extractor.write_data_block (buffer, buffer_length, offset) != Archive.Result.OK) {
                    break;
                }
            }
        }

        if (last_result != Archive.Result.EOF) {
            critical ("Error: %s (%d)", archive.error_string (), archive.errno ());
        }
    }

    // Compresses all files recursibly from location to the gzipped file.
    private static void compress (File location, File gzipped_file) throws Error {
        var to_write = File.new_for_path (gzipped_file.get_path ());
        if (to_write.query_exists ()) {
            to_write.delete ();
        }

        to_write.create (FileCreateFlags.REPLACE_DESTINATION);

        Archive.Write archive = new Archive.Write ();
        archive.set_format_zip ();
        archive.open_filename (to_write.get_path ());

        add_to_archive_recursive (location, location, archive);

        if (archive.close () != Archive.Result.OK) {
            critical ("Error : %s (%d)", archive.error_string (), archive.errno ());
        }
    }

    private static void add_to_archive_recursive (File initial_folder, File folder, Archive.Write archive) {
        try {
            var enumerator = folder.enumerate_children (FileAttribute.STANDARD_NAME, 0);

            FileInfo current_info;
            while ((current_info = enumerator.next_file ()) != null) {
                var current_file = folder.resolve_relative_path (current_info.get_name ());

                if (current_info.get_file_type () == FileType.DIRECTORY) {
                    add_to_archive_recursive (initial_folder, current_file, archive);
                } else {
                    GLib.FileInfo file_info = current_file.query_info (GLib.FileAttribute.STANDARD_SIZE, GLib.FileQueryInfoFlags.NONE);

                    FileInputStream input_stream = current_file.read ();
                    DataInputStream data_input_stream = new DataInputStream (input_stream);

                    // Add an entry to the archive
                    Archive.Entry entry = new Archive.Entry ();
                    entry.set_pathname (initial_folder.get_relative_path (current_file));
                    entry.set_size (file_info.get_size ());
                    entry.set_filetype ((uint) Posix.S_IFREG);
                    entry.set_perm (0644);

                    if (archive.write_header (entry) != Archive.Result.OK) {
                        critical ("Error writing '%s': %s (%d)", current_file.get_path (), archive.error_string (), archive.errno ());
                        return;
                    }

                    // Add the actual content of the file
                    size_t bytes_read;
                    uint8[64] buffer = new uint8[64];
                    while (data_input_stream.read_all (buffer, out bytes_read)) {
                        if (bytes_read <= 0) {
                            break;
                        }

                        archive.write_data (buffer, bytes_read);
                    }
                }
            }
        } catch (Error e) {
            critical ("Error: %s\n", e.message);
        }
    }


    /**
     * Takes care of the reference counting for files inside the archive.
     * This allows to multiple objects to reference the same file, and only
     * mark the file for deletion it if no other object is using it.
     */
    protected class FileCollector {
        private unowned File unarchived_location;
        private Gee.HashMap<string, File> for_deletion;
        private Gee.HashMap<string, int> ref_counter;

        public FileCollector (File _unarchived_location) {
            unarchived_location = _unarchived_location;

            for_deletion = new Gee.HashMap<string, File> ();
            ref_counter = new Gee.HashMap<string, int> ();
        }

        /**
         * Gets the number of times a file is being used
         */
        public int file_references (File file) {
            var file_basename = file.get_basename ();

            if (ref_counter.has_key (file_basename)) {
                return ref_counter.get (file_basename);
            } else {
                return 0;
            }
        }

        /**
         * Adds 1 to the ref counter for that file.
         */
        public void ref_file (File file) {
            var file_basename = file.get_basename ();
            if (for_deletion.has_key (file_basename)) {
                unmark_for_deletion (file);
            }

            var ref_count = file_references (file);
            ref_counter.set (file_basename, ref_count + 1);
            print ("File ref %d %s \n", ref_count + 1, file.get_basename ());
        }

        /**
         * Subtracts 1 on the ref counter for that file. If set to 0, the file will be marked for deletion
         */
        public void unref_file (File file) {
            var file_basename = file.get_basename ();

            var ref_count = file_references (file);
            if (ref_count > 0) {
                ref_counter.set (file_basename, ref_count - 1);

                if (ref_count == 1) {
                    mark_for_deletion (file);
                }
                print ("File unref %d %s \n", ref_count - 1, file.get_basename ());
            }
        }

        /**
         * Marks a file to be deleted and not saved to the archive. Said files will be deleted
         * when write_to_archive runs or when you manually call "delete_files_marked_for_deletion".
         *
         * Files will only be added to the list when they are inside the unarchived location
         */
        public void mark_for_deletion (File file) {
            if (file.get_path ().contains (unarchived_location.get_path ())) {
                for_deletion.set (file.get_basename (), file);
                print ("Marked for deletion: %s\n", file.get_basename ());
            }
        }

        /**
         * Unmarks a file previously marked for deletion.
         */
        public void unmark_for_deletion (File file) {
            for_deletion.unset (file.get_basename ());
            print ("unmarked for deletion: %s\n", file.get_basename ());
        }

        /**
         * Deletes all files whose ref counter is set to 0, or those marked for deletion
         */
        public void delete_files_marked_for_deletion () {
            foreach (var file in for_deletion.values) {
                try {
                    file.delete ();
                } catch (Error e) {
                    warning ("File could not be deleted %s\n", e.message);
                }
            };

            for_deletion.clear ();
        }
    }
}
