import { redirect, notFound } from 'next/navigation';

const API = process.env.API_URL ?? 'http://localhost:3000';

export default async function SlugRedirectPage({
  params,
}: {
  params: { slug: string };
}) {
  const res = await fetch(`${API}/p/b/${params.slug}`, {
    cache: 'no-store',
    redirect: 'manual',
  });

  if (!res.ok && res.status !== 302) {
    notFound();
  }

  const data = await res.json().catch(() => null);
  if (!data?.username) notFound();

  redirect(`/p/${data.username}`);
}
