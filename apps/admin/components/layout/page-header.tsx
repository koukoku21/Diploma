type Props = {
  title: string;
  description?: string;
  action?: React.ReactNode;
};

export function PageHeader({ title, description, action }: Props) {
  return (
    <div className="mb-6 flex items-start justify-between gap-4">
      <div>
        <h2 className="text-2xl font-semibold text-text-primary">{title}</h2>
        {description ? (
          <p className="mt-1 text-sm text-text-secondary">{description}</p>
        ) : null}
      </div>

      {action ? <div>{action}</div> : null}
    </div>
  );
}