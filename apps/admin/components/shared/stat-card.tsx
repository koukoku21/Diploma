type Props = {
  label: string;
  value: string | number;
  hint?: string;
};

export function StatCard({ label, value, hint }: Props) {
  return (
    <div className="rounded-3xl border border-border bg-bg-secondary p-5 shadow-soft">
      <p className="text-sm text-text-secondary">{label}</p>
      <p className="mt-3 text-3xl font-semibold text-text-primary">{value}</p>
      {hint ? <p className="mt-2 text-sm text-text-tertiary">{hint}</p> : null}
    </div>
  );
}