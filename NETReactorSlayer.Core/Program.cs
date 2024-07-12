﻿/*
    Copyright (C) 2021 CodeStrikers.org
    This file is part of NETReactorSlayer.
    NETReactorSlayer is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.
    NETReactorSlayer is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.
    You should have received a copy of the GNU General Public License
    along with NETReactorSlayer.  If not, see <http://www.gnu.org/licenses/>.
*/

using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading;
using NETReactorSlayer.Core.Abstractions;
using NETReactorSlayer.Core.Helper;
using NETReactorSlayer.Core.Stages;

namespace NETReactorSlayer.Core
{
    public class Program
    {
        public static void Main(string[] args)
        {
            if (!CheckArguments(args))
                return;

            Console.Title = ".NET Reactor Slayer (unofficial)";
            Console.OutputEncoding = Encoding.UTF8;
            Console.BackgroundColor = ConsoleColor.Black;
            Console.ForegroundColor = ConsoleColor.White;

            IOptions options = new Options(args);
            IContext context = new Context(options, new Logger());

            try
            {
                Console.Clear();
                context.Logger.PrintLogo();
            }
            catch { }

            if (context.Load())
            {
                DeobfuscateBegin(context);
                DeobfuscateEnd(context);
            }

            if (context.Options.NoPause)
                return;

            Console.WriteLine("\r\n  Press any key to exit . . .");
            Console.ReadKey();
        }

        private static bool CheckArguments(IReadOnlyList<string> args)
        {
            if (args.Count != 3 || args[0] != "--del-temp" ||
                !int.TryParse(args[1], out var id) || !File.Exists(args[2]))
                return true;

            try
            {
                if (Process.GetProcessById(id) is { } process)
                {
                    process.WaitForExit();
                    while (File.Exists(args[2]))
                    {
                        try { File.Delete(args[2]); }
                        catch { }

                        Thread.Sleep(1000);
                    }

                    Process.GetCurrentProcess().Kill();
                    return false;
                }
            }
            catch { }

            return true;
        }

        private static void DeobfuscateBegin(IContext context)
        {
            const int maxStackSize = 1024 * 1024 * 64;
            foreach (var thread in context.Options.Stages.Select(deobfuscatorStage => new Thread(() =>
                     {
                         try { deobfuscatorStage.Run(context); }
                         catch (Exception ex)
                         {
                             context.Logger.Error($"{deobfuscatorStage.GetType().Name}: {ex.Message}");
                         }
                     }, maxStackSize)))
            {
                thread.Start();
                thread.Join();
            }
        }

        private static void DeobfuscateEnd(IContext context)
        {
            if (context.Options.Stages.Any(x => x.GetType().Name.Equals(nameof(MethodInliner))))
                if (MethodInliner.InlinedMethods > 0)
                    context.Logger.Info(MethodInliner.InlinedMethods + " Methods inlined.");
                else
                    context.Logger.Warn("Couldn't find any outline method.");

            if (CodeVirtualizationUtils.Detect(context))
                context.Logger.Warn(
                    "WARNING: CODE VIRTUALIZATION HAS BEEN DETECTED, INCOMPLETE DEOBFUSCATION OF THE ASSEMBLY MAY RESULT.");

            context.Save();
        }
    }
}