import { PageHeader } from "@/components/layout/page-header";
import { StatCard } from "@/components/shared/stat-card";

export default function DashboardPage() {
  return (
    <div>
      <PageHeader
        title="Dashboard"
        description="Overview of platform moderation and operations"
      />

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
        <StatCard label="Total Users" value="1,248" hint="All registered users" />
        <StatCard label="Masters" value="214" hint="Approved + pending + rejected" />
        <StatCard label="Pending Verification" value="18" hint="Require review" />
        <StatCard label="Bookings Today" value="63" hint="Across the platform" />
      </div>

      <div className="mt-6 grid gap-6 xl:grid-cols-2">
        <section className="rounded-3xl border border-border bg-bg-secondary p-5">
          <h3 className="text-lg font-semibold text-text-primary">
            Pending master applications
          </h3>
          <div className="mt-4 space-y-3">
            {["Aigerim T.", "Dana K.", "Madina S."].map((name) => (
              <div
                key={name}
                className="flex items-center justify-between rounded-2xl border border-border bg-bg-tertiary px-4 py-3"
              >
                <div>
                  <p className="font-medium text-text-primary">{name}</p>
                  <p className="text-sm text-text-secondary">
                    Waiting for moderation
                  </p>
                </div>
                <button className="rounded-full bg-gold px-4 py-2 text-sm font-medium text-bg-primary">
                  Review
                </button>
              </div>
            ))}
          </div>
        </section>

        <section className="rounded-3xl border border-border bg-bg-secondary p-5">
          <h3 className="text-lg font-semibold text-text-primary">
            Recent activity
          </h3>
          <div className="mt-4 space-y-3">
            {[
              "New booking created",
              "Master profile submitted",
              "Service template updated",
              "Review posted",
            ].map((item, idx) => (
              <div
                key={idx}
                className="rounded-2xl border border-border bg-bg-tertiary px-4 py-3 text-sm text-text-secondary"
              >
                {item}
              </div>
            ))}
          </div>
        </section>
      </div>
    </div>
  );
}