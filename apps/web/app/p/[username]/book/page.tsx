import { notFound } from 'next/navigation';
import { getMasterProfile } from '@/lib/api';
import BookingForm from './BookingForm';

export default async function BookPage({ params }: { params: { username: string } }) {
  let master;
  try {
    master = await getMasterProfile(params.username);
  } catch {
    notFound();
  }

  if (!master.isBookingLinkActive) notFound();

  return <BookingForm username={params.username} services={master.services} />;
}
