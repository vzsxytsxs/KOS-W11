using System;
using System.IO;
using System.Windows.Forms;
using Microsoft.Web.WebView2.WinForms;

internal static class WebView2Smoke
{
    private const string ResultPath = @"C:\Users\Public\kos-webview2-smoke-result.txt";

    [STAThread]
    private static void Main()
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);

        using (var window = new Form())
        using (var view = new WebView2())
        using (var timer = new Timer())
        {
            window.Text = "KOS WebView2 smoke test";
            window.Width = 420;
            window.Height = 300;
            view.Dock = DockStyle.Fill;
            window.Controls.Add(view);

            timer.Interval = 30000;
            timer.Tick += (sender, args) =>
            {
                File.WriteAllText(ResultPath, "FAIL: timeout waiting for WebView2");
                window.Close();
            };

            window.Shown += async (sender, args) =>
            {
                try
                {
                    timer.Start();
                    await view.EnsureCoreWebView2Async(null);
                    view.CoreWebView2.NavigationCompleted += async (navSender, navArgs) =>
                    {
                        try
                        {
                            if (!navArgs.IsSuccess)
                                throw new Exception("Navigation failed: " + navArgs.WebErrorStatus);

                            string value = await view.CoreWebView2.ExecuteScriptAsync(
                                "document.getElementById('proof').textContent");
                            if (value != "\"KOS_WEBVIEW2_OK\"")
                                throw new Exception("Unexpected DOM value: " + value);

                            File.WriteAllText(ResultPath, "PASS: HTML and JavaScript rendered by WebView2");
                        }
                        catch (Exception ex)
                        {
                            File.WriteAllText(ResultPath, "FAIL: " + ex);
                        }
                        finally
                        {
                            timer.Stop();
                            window.Close();
                        }
                    };
                    view.CoreWebView2.NavigateToString(
                        "<!doctype html><html><body><span id='proof'>KOS_WEBVIEW2_OK</span></body></html>");
                }
                catch (Exception ex)
                {
                    timer.Stop();
                    File.WriteAllText(ResultPath, "FAIL: " + ex);
                    window.Close();
                }
            };

            Application.Run(window);
        }
    }
}
