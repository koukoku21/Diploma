import { PageHeader } from "@/components/layout/page-header";

const masters = [
  {
    id: "1",
    name: "Aigerim T.",
    status: "PENDING",
    specialization: "MANICURE",
    city: "Astana",
  },
  {
    id: "2",
    name: "Dana K.",
    status: "APPROVED",
    specialization: "HAIRCUT",
    city: "Astana",
  },
  {
    id: "3",
    name: "Madina S.",
    status: "REJECTED",
    specialization: "MAKEUP",
    city: "Astana",
  },
];

function StatusBadge({ status }: { status: string }) {
  const map: Record<string, string> = {
    PENDING: "bg-gold/10 text-gold",
    APPROVED: "bg-green-500/10 text-green-400",
    REJECTED: "bg-rose/10 text-rose",
  };

  return (
    <span className={`rounded-full px-3 py-1 text-xs font-medium ${map[status]}`}>
      {status}
    </span>
  );
}

export default function MastersPage() {
  return (
    <div>
      <PageHeader
        title="Masters"
        description="Review and moderate master profiles"
        action={
          <button className="rounded-full bg-gold px-4 py-2 text-sm font-medium text-bg-primary">
            Export
          </button>
        }
      />

      <div className="overflow-hidden rounded-3xl border border-border bg-bg-secondary">
        <table className="w-full border-collapse text-left">
          <thead className="bg-bg-tertiary">
            <tr className="text-sm text-text-secondary">
              <th className="px-5 py-4">Name</th>
              <th className="px-5 py-4">Status</th>
              <th className="px-5 py-4">Specialization</th>
              <th className="px-5 py-4">City</th>
              <th className="px-5 py-4">Actions</th>
            </tr>
          </thead>
          <tbody>
            {masters.map((master) => (
              <tr key={master.id} className="border-t border-border">
                <td className="px-5 py-4 text-text-primary">{master.name}</td>
                <td className="px-5 py-4">
                  <StatusBadge status={master.status} />
                </td>
                <td className="px-5 py-4 text-text-secondary">
                  {master.specialization}
                </td>
                <td className="px-5 py-4 text-text-secondary">{master.city}</td>
                <td className="px-5 py-4">
                  <div className="flex gap-2">
                    <button className="rounded-full border border-border px-3 py-1.5 text-sm text-text-secondary hover:bg-white/5">
                      View
                    </button>
                    <button className="rounded-full bg-gold px-3 py-1.5 text-sm font-medium text-bg-primary">
                      Approve
                    </button>
                    <button className="rounded-full border border-rose/30 px-3 py-1.5 text-sm text-rose hover:bg-rose/10">
                      Reject
                    </button>
                  </div>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}