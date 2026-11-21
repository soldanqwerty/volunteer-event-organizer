-- Політики доступу до bucket `images` у Supabase Storage (лаб. №6).
-- Bucket публічний: читати файли за посиланням може будь-хто.
-- Застосунок не використовує Supabase Auth (користувачі входять через
-- Firebase), тому завантаження й видалення дозволено ролі anon, але
-- лише в цьому bucket, лише в папках covers/ та avatars/ і лише зображень.
-- Методичка допускає такий варіант для навчальних цілей.

create policy "images: read"
on storage.objects for select
to anon
using (bucket_id = 'images');

create policy "images: upload pictures"
on storage.objects for insert
to anon
with check (
  bucket_id = 'images'
  and (storage.foldername(name))[1] in ('covers', 'avatars')
  and lower(storage.extension(name)) in ('jpeg', 'jpg', 'png', 'webp')
);

create policy "images: delete"
on storage.objects for delete
to anon
using (
  bucket_id = 'images'
  and (storage.foldername(name))[1] in ('covers', 'avatars')
);
