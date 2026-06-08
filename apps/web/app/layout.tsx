import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: 'Miraku — запись к мастеру',
  description: 'Запишитесь к мастеру красоты в несколько кликов',
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="ru">
      <body className="max-w-md mx-auto min-h-screen bg-bg-primary">{children}</body>
    </html>
  );
}
