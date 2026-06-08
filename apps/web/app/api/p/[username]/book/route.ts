import { NextRequest, NextResponse } from 'next/server';

const API = process.env.API_URL ?? 'http://localhost:3001';

export async function POST(req: NextRequest, { params }: { params: { username: string } }) {
  const body = await req.json();
  const res = await fetch(`${API}/p/${params.username}/book`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  const data = await res.json();
  return NextResponse.json(data, { status: res.status });
}
