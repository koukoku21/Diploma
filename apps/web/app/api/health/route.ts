export async function GET() {
  const apiUrl = process.env.API_URL ?? 'NOT_SET';
  try {
    const res = await fetch(`${apiUrl}/p/aigerim_nail`, { cache: 'no-store' });
    const data = await res.json();
    return Response.json({ ok: true, apiUrl, status: res.status, master: data?.user?.name });
  } catch (e) {
    return Response.json({ ok: false, apiUrl, error: String(e) });
  }
}
