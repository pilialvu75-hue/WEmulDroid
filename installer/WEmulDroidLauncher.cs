// WEmulDroid Windows launcher: stable desktop target for Start Menu, installer
// and updates. Windows PowerShell 5.1 remains the GUI engine for this prototype.
// Development installers run local scripts using RemoteSigned. A future signed
// production build will require AllSigned via the SIGNED_RELEASE define.
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Text;
using System.Windows.Forms;

[assembly: AssemblyTitle("WEmulDroid")]
[assembly: AssemblyDescription("Android virtual device desktop launcher")]
[assembly: AssemblyCompany("WEmulDroid")]
[assembly: AssemblyProduct("WEmulDroid")]

internal static class Program
{
    [STAThread]
    private static int Main(string[] args)
    {
        string root = AppDomain.CurrentDomain.BaseDirectory;
        string file = Path.Combine(root, "src", "Lab.ps1");
        if (!File.Exists(file))
        {
            MessageBox.Show("WEmulDroid installation is incomplete (src\\Lab.ps1 missing).",
                "WEmulDroid", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 2;
        }

        string avd = args.Length == 1 && args[0] == "--play"
            ? "WEmulDroid_Play_API_35" : "WEmulDroid_API_35";
        if (args.Length > 1 || (args.Length == 1 && args[0] != "--play"))
        {
            MessageBox.Show("Unsupported launcher arguments.", "WEmulDroid",
                MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return 3;
        }

        try
        {
            string quoted = "\"" + file.Replace("\"", "\\\"") + "\"";
#if SIGNED_RELEASE
            const string executionPolicy = "AllSigned";
#else
            const string executionPolicy = "RemoteSigned";
#endif
            ProcessStartInfo start = new ProcessStartInfo
            {
                FileName = Path.Combine(Environment.GetFolderPath(
                    Environment.SpecialFolder.System), "WindowsPowerShell",
                    "v1.0", "powershell.exe"),
                Arguments = "-NoProfile -STA -ExecutionPolicy " + executionPolicy + " -File "
                    + quoted + " -AvdName " + avd,
                UseShellExecute = false,
                CreateNoWindow = true,
                WorkingDirectory = root
            };
            using (Process process = Process.Start(start))
            {
                if (process == null) throw new InvalidOperationException("Cannot start PowerShell.");
                process.WaitForExit();
                if (process.ExitCode != 0)
                {
                    MessageBox.Show(
                        "WEmulDroid terminated with code " + process.ExitCode
                        + ". Open the app again or inspect its diagnostic reports."
                        + "\nIf Windows rejects a script, check its trusted publisher signature.",
                        "WEmulDroid", MessageBoxButtons.OK, MessageBoxIcon.Warning);
                }
                return process.ExitCode;
            }
        }
        catch (Exception exception)
        {
            MessageBox.Show("Cannot start WEmulDroid:\n" + exception.Message,
                "WEmulDroid", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
    }
}
