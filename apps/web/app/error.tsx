'use client';

export default function Error({ error }: { error: Error }) {
  return (
    <div className="flex flex-col items-center justify-center min-h-screen text-center px-4">
      <p className="text-6xl mb-4">⚠️</p>
      <h1 className="text-xl font-semibold text-gray-800 mb-2">Что-то пошло не так</h1>
      <p className="text-gray-500 text-sm">{error.message}</p>
    </div>
  );
}
