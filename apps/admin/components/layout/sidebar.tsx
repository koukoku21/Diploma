"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import {
  LayoutDashboard,
  Users,
  UserRoundCheck,
  CalendarDays,
  MessageSquareText,
  Settings,
  ClipboardList,
} from "lucide-react";
import clsx from "clsx";

const items = [
  { href: "/", label: "Dashboard", icon: LayoutDashboard },
  { href: "/masters", label: "Masters", icon: UserRoundCheck },
  { href: "/users", label: "Users", icon: Users },
  { href: "/service-templates", label: "Service Templates", icon: ClipboardList },
  { href: "/bookings", label: "Bookings", icon: CalendarDays },
  { href: "/reviews", label: "Reviews", icon: MessageSquareText },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function Sidebar() {
  const pathname = usePathname();

  return (
    <aside className="hidden w-72 shrink-0 border-r border-border bg-bg-secondary lg:block">
      <div className="px-6 py-6">
        <p className="text-sm uppercase tracking-[0.25em] text-gold">Miraku</p>
        <h2 className="mt-2 text-2xl font-semibold text-text-primary">Admin</h2>
      </div>

      <nav className="px-4 pb-6">
        <div className="space-y-1">
          {items.map((item) => {
            const Icon = item.icon;
            const active =
              item.href === "/"
                ? pathname === "/"
                : pathname.startsWith(item.href);

            return (
              <Link
                key={item.href}
                href={item.href}
                className={clsx(
                  "flex items-center gap-3 rounded-2xl px-4 py-3 text-sm transition",
                  active
                    ? "bg-gold/10 text-gold"
                    : "text-text-secondary hover:bg-white/5 hover:text-text-primary"
                )}
              >
                <Icon size={18} />
                <span>{item.label}</span>
              </Link>
            );
          })}
        </div>
      </nav>
    </aside>
  );
}