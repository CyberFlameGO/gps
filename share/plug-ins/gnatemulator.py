"""
This plug-in creates buttons on the toolbar to conveniently
debug, and run programs on GNATemulator.

The following is required:
 - the GNATemulator for your target should be present on the PATH, if not the
   buttons won't be displayed.
"""

import GPS
from modules import Module
import workflows.promises as promises
import workflows
from os_utils import locate_exec_on_path
from gps_utils.console_process import Console_Process


def log(msg):
    GPS.Logger("GNATemulator").log(msg)


class GNATemulator(Module):

    # List of targets
    # These are created lazily the first time we find the necessary tools on
    # the command line. This is done so that we do not have to toggle the
    # visibility of these build targets too often, since that also trigger
    # the reparsing of Makefiles, for instance, and a refresh of all GUI
    # elements related to any build target.
    __buildTargets = []

    def __create_targets_lazily(self):
        active = self.gnatemu_on_path()

        if not self.__buildTargets and active:
            targets_def = [
                ["Run with Emulator", "run-with-emulator",
                    self.__emu_wf, "gps-emulatorloading-run-symbolic"],
                ["Debug with Emulator", "debug-with-emulator",
                    self.__emu_debug_wf, "gps-emulatorloading-debug-symbolic"]]

            for target in targets_def:
                workflows.create_target_from_workflow(
                    target[0], target[1], target[2], target[3])
                self.__buildTargets.append(GPS.BuildTarget(target[0]))

        if active:
            for b in self.__buildTargets:
                b.show()
        else:
            for b in self.__buildTargets:
                b.hide()

    def get_gnatemu_name(self):
        target = GPS.get_target()
        if target:
            prefix = target + '-'
        else:
            prefix = ""

        return prefix + "gnatemu"

    def gnatemu_on_path(self):
        bin = self.get_gnatemu_name()

        gnatemu = locate_exec_on_path(bin)
        return gnatemu != ''

    def run_gnatemu(self, args):
        gnatemu = self.get_gnatemu_name()
        proj = GPS.Project.root()
        project_arg = "-P%s " % proj.file().name() if proj else ""
        var_args = GPS.Project.scenario_variables_cmd_line("-X")

        jargs = "%s %s %s" % (project_arg, var_args, " ".join(args))
        GPS.Console("Messages").write("Running in emulator: %s %s" %
                                      (gnatemu, jargs))

        #  - Open a console for each GNATemu run
        #  - Don't close the console when GNAtemu exits so we have time to see
        #    the results
        #  - GNATemu should be in the task manager
        Console_Process(gnatemu, args=jargs, force=True,
                        close_on_exit=False, task_manager=True)

    def __error_exit(self, msg=""):
        """ Emit an error and reset the workflows """
        GPS.Console("Messages").write(msg + " [workflow stopped]")

    ###############################
    # The following are workflows #
    ###############################

    def __emu_wf(self, main_name):
        """
        Workflow to build and run the program in the emulator.
        """

        if main_name is None:
            self.__error_exit(msg="Main not specified")
            return

        # STEP 1.5 Build it
        log("Building Main %s..." % main_name)
        builder = promises.TargetWrapper("Build Main")
        r0 = yield builder.wait_on_execute(main_name)
        if r0 is not 0:
            self.__error_exit(msg="Build error.")
            return

        log("... done.")

        # STEP 2 load with Emulator
        b = GPS.Project.root().get_executable_name(GPS.File(main_name))
        d = GPS.Project.root().object_dirs()[0]
        obj = d + b
        self.run_gnatemu([obj])

    def __emu_debug_wf(self, main_name):
        """
        Workflow to debug a program under the emulator.
        """

        # STEP 1.0 get main name
        if main_name is None:
            self.__error_exit(msg="Main not specified.")
            return

        # STEP 1.5 Build it
        log("Building Main %s..." % main_name)
        builder = promises.TargetWrapper("Build Main")
        r0 = yield builder.wait_on_execute(main_name)
        if r0 is not 0:
            self.__error_exit(msg="Build error.")
            return
        binary = GPS.Project.root().get_executable_name(GPS.File(main_name))

        log("... done.")

        # STEP 2 launch debugger

        debugger_promise = promises.DebuggerWrapper(GPS.File(binary))

        # block execution until debugger is free
        r3 = yield debugger_promise.wait_and_send(cmd="", block=False)
        if not r3:
            self.__error_exit("Could not initialize the debugger.")
            r3 = yield debugger_promise.wait_and_send(cmd="", block=False)
            return
        log("... done.")

        # STEP 3 load with Emulator
        # To have GNATemu console in the debugger perspective we have to start
        # GNATemu after gdb initialization.
        d = GPS.Project.root().object_dirs()[0]
        obj = d + binary
        self.run_gnatemu(["-g", obj])

        # STEP 4 target and run the program
        log("Sending debugger command to target the emulator...")
        r3 = yield debugger_promise.wait_and_send(
            cmd="target remote localhost:1234",
            timeout=4000)
        interest = "Remote debugging using localhost:1234"

        if interest not in r3:
            self.__error_exit("Could not connect to the target.")
            return

        log("... done.")

    def setup(self):
        self.__create_targets_lazily()

    def project_view_changed(self):
        self.__create_targets_lazily()