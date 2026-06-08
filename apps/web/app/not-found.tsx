export default function NotFound() {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen text-center px-4"
      style={{ background: '#0a0a0f' }}>
      <p className="text-5xl font-display font-semibold mb-4" style={{ color: '#c9a96e' }}>404</p>
      <h1 className="text-xl font-semibold text-text-primary mb-2">Мастер не найден</h1>
      <p className="text-text-secondary text-sm">Проверьте правильность ссылки</p>
    </div>
  );
}
