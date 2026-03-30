"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { setAuthToken } from "@/lib/api/client";

export default function LoginPage() {
  const router = useRouter();
  const [phone, setPhone] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);

    try {
      // Временный mock login.
      // Потом заменим на реальный admin auth endpoint.
      const fakeToken = "admin-dev-token";
      localStorage.setItem("miraku_admin_token", fakeToken);
      setAuthToken(fakeToken);
      router.push("/");
    } finally {
      setLoading(false);
    }
  }

  return (
    <main className="flex min-h-screen items-center justify-center bg-bg-primary px-4">
      <div className="w-full max-w-md rounded-3xl border border-border bg-bg-secondary p-8 shadow-soft">
        <div className="mb-8">
          <p className="mb-2 text-sm uppercase tracking-[0.22em] text-gold">
            Miraku
          </p>
          <h1 className="text-3xl font-semibold text-text-primary">
            Admin Panel
          </h1>
          <p className="mt-2 text-sm text-text-secondary">
            Internal moderation and operations dashboard
          </p>
        </div>

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="mb-2 block text-sm text-text-secondary">
              Login
            </label>
            <input
              value={phone}
              onChange={(e) => setPhone(e.target.value)}
              placeholder="admin@miraku.kz"
              className="w-full rounded-2xl border border-border bg-bg-tertiary px-4 py-3 text-text-primary outline-none transition focus:border-gold"
            />
          </div>

          <div>
            <label className="mb-2 block text-sm text-text-secondary">
              Password
            </label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="••••••••"
              className="w-full rounded-2xl border border-border bg-bg-tertiary px-4 py-3 text-text-primary outline-none transition focus:border-gold"
            />
          </div>

          <button
            type="submit"
            disabled={loading}
            className="mt-2 w-full rounded-full bg-gold px-4 py-3 font-semibold text-bg-primary transition hover:opacity-90 disabled:opacity-60"
          >
            {loading ? "Signing in..." : "Sign in"}
          </button>
        </form>
      </div>
    </main>
  );
}