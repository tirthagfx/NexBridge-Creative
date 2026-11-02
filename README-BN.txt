NEXBRIDGE CREATIVE — ADMIN PANEL PACKAGE
========================================

এই প্যাকেজে যা আছে
------------------
index.html             বর্তমান public website (মূল design/CSS রেখে CMS সংযুক্ত)
careers.html           Careers page (live job list + application submission)
admin.html             Single-admin dashboard
config.js              Supabase project URL ও anon key বসানোর জায়গা
public-site.js         Public website ↔ Supabase integration
supabase-schema.sql    Database tables, access policies, media storage ও starter services/jobs
assets/                Website-এর local image রাখার folder

Admin Panel-এ আছে
-----------------
- Overview dashboard ও record counts
- Portfolio project add/edit/delete, publish/hide, image URL এবং Storage upload
- Services add/edit/delete ও subcategories
- Team member add/edit/delete ও photo upload
- Jobs post/edit/delete, open/close
- Applications দেখা, CV/portfolio খোলা, status update (Pending/Shortlisted/Interview/Rejected/Hired)
- Contact/project inquiries দেখা
- Website settings key/value editor
- Single administrator login; public signup নেই

LIVE করার জন্য প্রয়োজনীয় setup (একবার করতে হবে)
-----------------------------------------------
1. https://supabase.com এ একটি project তৈরি করো। Database password নিরাপদে রাখবে।
2. Supabase Dashboard → SQL Editor → New query খুলে supabase-schema.sql-এর সম্পূর্ণ SQL paste করে Run করো।
3. Supabase Dashboard → Project Settings → API থেকে Project URL এবং anon/public key কপি করো।
4. config.js খুলে নিচের দুটি value বসাও:
   url: 'https://YOUR-PROJECT.supabase.co'
   anonKey: 'YOUR_SUPABASE_ANON_PUBLIC_KEY'
   IMPORTANT: service_role / secret key কখনো config.js বা GitHub-এ দেবে না।
5. Supabase Dashboard → Authentication → Users → Add user দিয়ে নিজের admin email/password তৈরি করো। Email confirm করে রাখো।
6. ওই user-এর UUID কপি করো। Supabase → SQL Editor-এ নিচের query চালাও (UUID নিজেরটা দিয়ে বদলাবে):

   insert into public.admin_users(user_id)
   values ('YOUR-AUTH-USER-UUID');

   এই allow-list-এ যাকে যোগ করবে শুধু সেই account-ই Admin Panel-এ ঢুকতে পারবে। Single admin চাইলে আর কাউকে add করবে না।
7. সব ফাইল একই website root folder-এ রাখো। GitHub Pages-এ push করো।
8. Website: https://YOUR-DOMAIN/ অথবা GitHub Pages URL
   Admin:   https://YOUR-DOMAIN/admin.html
   Careers: https://YOUR-DOMAIN/careers.html

ব্যবহার
-------
- Admin Panel-এ admin email/password দিয়ে sign in করো।
- Portfolio / Team image upload করলে তা Supabase Storage-এর nexbridge-media bucket-এ যাবে।
- নতুন Project/Service/Team/Job যোগ করলে Public website-এ visible/published হলে দেখাবে।
- Careers page-এর application এবং Homepage-এর project inquiry Supabase database-এ জমা হবে।
- Website Settings-এ setting_key ও setting_value যোগ করে supported keys আপডেট করতে পারো:
  hero_intro, about_paragraph_1, about_paragraph_2, contact_email, contact_phone, location
- Contact/social links-এর সব href setting দিয়ে পরিবর্তন করা এখনো স্বয়ংক্রিয় নয়; প্রয়োজন হলে HTML-এ URL update করতে হবে।

নিরাপত্তা
---------
- config.js-এ শুধু Supabase anon/public key থাকবে; database RLS policy data সুরক্ষা দেয়।
- Admin password কখনো website code-এ রাখবে না।
- Admin account-এর password অন্য কোথাও reuse করবে না এবং 2FA চালু রাখো।
- GitHub Pages static hosting; admin authentication ও data persistence Supabase পরিচালনা করে।

গুরুত্বপূর্ণ সীমাবদ্ধতা
----------------------
এই ZIP-এ code এবং database setup দেওয়া হয়েছে। Supabase project তৈরি, API key বসানো এবং admin user allow-list-এ যোগ করা ছাড়া live login/database কাজ করবে না। আমি তোমার Supabase account-এ প্রবেশ করে project তৈরি বা credentials বসাতে পারি না। Setup সম্পন্ন হলে dashboard-এর CRUD ও form submission চালু হবে।
Website deployment refresh
