// OP7 build fix (build-layer, not device-specific).
//
// Glean's Bootstrap_CONDA* tasks install a Miniconda3 environment into a single
// shared directory under the Gradle user home:
//   <gradleUserHome>/glean/bootstrap-24.3.0-0/Miniconda3
// The bundled Miniconda installer is NON-idempotent: if that directory already
// exists but is incomplete/empty (left behind by a prior failed run on a reused
// runner VM, or restored from a stale cache), the installer aborts with
//   ERROR: File or directory already exists: '.../Miniconda3'
//
// Fix: immediately before each bootstrap task executes, if the Miniconda3 directory
// exists but is NOT a verified-complete install (no runnable bin/conda), delete it so
// the installer recreates it cleanly. A complete install is left untouched, so the
// fast path (plugin skips / reuses) is preserved. Generic capability check, not
// OnePlus-specific. Applied via the `-I` init script from the build step.

allprojects { p ->
    p.tasks.configureEach { t ->
        if (t.name.startsWith('Bootstrap_CONDA')) {
            t.doFirst {
                def home = p.getGradle().gradleUserHomeDir
                def dir = new File(home, "glean/bootstrap-24.3.0-0/Miniconda3")
                def conda = new File(dir, "bin/conda")
                if (dir.exists() && !(conda.exists() && conda.canExecute())) {
                    t.logger.lifecycle("OP7: removing incomplete Miniconda3 at ${dir} before bootstrap")
                    dir.deleteDir()
                }
            }
        }
    }
}
