"use client";

import { useRouter } from "next/navigation";

export function Topbar() {
  const router = useRouter();

  function handleLogout() {
    localStorage.removeItem("miraku_admin_token");
    router.push("/login");
  }

  return (
    <header className="flex items-center justify-between border-b border-border bg-bg-primary px-6 py-4">
      <div>
        <p className="text-sm text-text-secondary">Platform Operations</p>
        <h1 className="text-lg font-semibold text-text-primary">
          Miraku Admin Panel
        </h1>
      </div>

      <div className="flex items-center gap-3">
        <div className="rounded-full border border-border bg-bg-secondary px-4 py-2 text-sm text-text-secondary">
          Admin
        </div>
        <button
          onClick={handleLogout}
          className="rounded-full border border-border px-4 py-2 text-sm text-text-secondary transition hover:bg-white/5 hover:text-text-primary"
        >
          Logout
        </button>
      </div>
    </header>
  );
}