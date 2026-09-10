using System;
using System.Runtime.InteropServices;
using SolidWorks.Interop.sldworks;

// Read-only probe. This class never starts, edits, saves or closes SOLIDWORKS.
public static class StarterConnection
{
    public static string Probe(string expectedRevisionPrefix)
    {
        ISldWorks app = (ISldWorks)Marshal.GetActiveObject("SldWorks.Application");
        string revision = app.RevisionNumber();
        if (!revision.StartsWith(expectedRevisionPrefix, StringComparison.Ordinal))
            throw new InvalidOperationException("Revision mismatch: observed " + revision +
                "; expected prefix " + expectedRevisionPrefix + ". Review compatibility first.");
        return "CONNECTED revision=" + revision + " pid=" + app.GetProcessID();
    }

    // For future drivers: use with explicit owned references, not title-only fallback.
    public static bool SameComObject(object first, object second)
    {
        if (first == null || second == null) return false;
        IntPtr a = IntPtr.Zero, b = IntPtr.Zero;
        try
        {
            a = Marshal.GetIUnknownForObject(first);
            b = Marshal.GetIUnknownForObject(second);
            return a == b;
        }
        finally
        {
            if (a != IntPtr.Zero) Marshal.Release(a);
            if (b != IntPtr.Zero) Marshal.Release(b);
        }
    }
}
