# LandGIS — Database Schema

Dokumentasi skema database LandGIS. Nama kolom menggunakan bahasa Inggris dengan format `snake_case`, sedangkan fungsi kolom dijelaskan dalam bahasa Indonesia.

## Daftar Tabel

1. [Penawaran (Offerings)](#offerings) (`offerings`)
2. [Rincian Penawaran (Offering Items)](#offering-items) (`offering_items`)
3. [Proyek (Projects)](#projects) (`projects`)
4. [Klien (Clients)](#clients) (`clients`)
5. [Dokumen (Documents)](#documents) (`documents`)
6. [Relasi Dokumen (Document Links)](#document-links) (`document_links`)
7. [Laporan (Reports)](#reports) (`reports`)

---

<a id="offerings"></a>
## Penawaran (Offerings) — `offerings`

| No. | Kolom | Fungsi |
|---:|---|---|
| 1 | `offering_id` | ID unik penawaran |
| 2 | `offering_number` | Nomor dokumen penawaran |
| 3 | `project_name` | Nama pekerjaan atau proyek yang ditawarkan |
| 4 | `client_id` | Referensi ke tabel clients |
| 5 | `service_type` | Jenis pekerjaan, misalnya survei lahan atau pemetaan GIS |
| 6 | `location` | Lokasi pekerjaan |
| 7 | `area_m2` | Estimasi luas lahan dalam m² |
| 8 | `scope_of_work` | Ruang lingkup atau rincian pekerjaan |
| 9 | `valid_until` | Tanggal berakhirnya masa berlaku penawaran |
| 10 | `status` | Status: draft, sent, accepted, rejected, expired |
| 11 | `created_at` | Waktu penawaran dibuat |
| 12 | `updated_at` | Waktu terakhir data penawaran diperbarui |

<a id="offering-items"></a>
## Rincian Penawaran (Offering Items) — `offering_items`

| No. | Kolom | Fungsi |
|---:|---|---|
| 1 | `offering_item_id` | ID unik rincian penawaran |
| 2 | `offering_id` | Referensi ke tabel offerings |
| 3 | `item_name` | Nama pekerjaan atau item biaya |
| 4 | `description` | Deskripsi item |
| 5 | `unit` | Satuan pekerjaan, misalnya hektare, hari, atau paket |
| 6 | `quantity` | Volume pekerjaan |
| 7 | `unit_price` | Harga per satuan |
| 8 | `subtotal` | Volume dikalikan harga satuan |
| 9 | `created_at` | Waktu item dibuat |
| 10 | `updated_at` | Waktu item diperbarui |

<a id="projects"></a>
## Proyek (Projects) — `projects`

| No. | Kolom | Fungsi |
|---:|---|---|
| 1 | `project_id` | ID unik proyek |
| 2 | `project_number` | Nomor proyek |
| 3 | `project_name` | Nama proyek |
| 4 | `offering_id` | Referensi penawaran asal, boleh kosong |
| 5 | `client_id` | Referensi ke tabel clients |
| 6 | `project_type` | Jenis proyek atau pekerjaan |
| 7 | `description` | Deskripsi dan tujuan proyek |
| 8 | `location` | Lokasi pelaksanaan proyek |
| 9 | `area_m2` | Luas area proyek dalam m² |
| 10 | `start_date` | Tanggal mulai proyek |
| 11 | `end_date` | Target tanggal selesai |
| 12 | `actual_end_date` | Tanggal selesai aktual |
| 13 | `budget_amount` | Anggaran proyek yang disetujui |
| 14 | `actual_cost` | Total biaya aktual proyek, dapat dihitung dari pengeluaran |
| 15 | `progress_percentage` | Persentase progres proyek |
| 16 | `project_manager_id` | Referensi pengguna penanggung jawab proyek |
| 17 | `status` | Status: planning, in_progress, on_hold, completed, cancelled |
| 18 | `created_at` | Waktu proyek dibuat |
| 19 | `updated_at` | Waktu terakhir data diperbarui |

<a id="clients"></a>
## Klien (Clients) — `clients`

| No. | Kolom | Fungsi |
|---:|---|---|
| 1 | `client_id` | ID unik klien |
| 2 | `client_number` | Nomor kode klien |
| 3 | `client_type` | Jenis klien: individual, company, government, organization |
| 4 | `client_name` | Nama klien atau organisasi |
| 5 | `contact_person` | Nama orang yang dapat dihubungi |
| 6 | `email` | Email klien |
| 7 | `phone` | Nomor telepon klien |
| 8 | `address` | Alamat klien |
| 9 | `city` | Kota atau kabupaten klien |
| 10 | `tax_number` | Nomor pajak jika diperlukan |
| 11 | `notes` | Catatan tambahan tentang klien |
| 12 | `created_at` | Waktu data klien dibuat |
| 13 | `updated_at` | Waktu terakhir data klien diperbarui |

<a id="documents"></a>
## Dokumen (Documents) — `documents`

| No. | Kolom | Fungsi |
|---:|---|---|
| 1 | `document_id` | ID unik dokumen |
| 2 | `document_number` | Nomor dokumen jika ada |
| 3 | `document_name` | Nama dokumen |
| 4 | `document_type` | Kategori dokumen: proposal, RAB, report, map, attachment, etc. |
| 5 | `file_name` | Nama file asli |
| 6 | `file_url` | Lokasi atau referensi file |
| 7 | `mime_type` | Jenis file, misalnya application/pdf |
| 8 | `file_size_bytes` | Ukuran file dalam byte |
| 9 | `uploaded_by` | ID pengguna yang mengunggah |
| 10 | `uploaded_at` | Waktu file diunggah |
| 11 | `updated_at` | Waktu metadata terakhir diperbarui |

<a id="document-links"></a>
## Relasi Dokumen (Document Links) — `document_links`

| No. | Kolom | Fungsi |
|---:|---|---|
| 1 | `document_link_id` | ID unik relasi dokumen |
| 2 | `document_id` | Referensi ke tabel documents |
| 3 | `entity_type` | Jenis entitas terkait: offering, project, atau client |
| 4 | `entity_id` | ID entitas terkait |
| 5 | `created_at` | Waktu relasi dibuat |

<a id="reports"></a>
## Laporan (Reports) — `reports`

| No. | Kolom | Fungsi |
|---:|---|---|
| 1 | `report_id` | ID unik laporan |
| 2 | `report_number` | Nomor laporan |
| 3 | `report_name` | Nama laporan |
| 4 | `report_type` | Jenis laporan: project, financial, offering, land |
| 5 | `project_id` | Referensi proyek jika laporan khusus proyek, boleh kosong |
| 6 | `client_id` | Referensi klien jika relevan, boleh kosong |
| 7 | `period_start` | Awal periode laporan |
| 8 | `period_end` | Akhir periode laporan |
| 9 | `report_status` | Status: draft, generated, published |
| 10 | `file_url` | Lokasi file laporan yang dihasilkan |
| 11 | `generated_by` | ID pengguna pembuat laporan |
| 12 | `generated_at` | Waktu laporan dibuat |
| 13 | `created_at` | Waktu data laporan dicatat |

## Catatan Relasi

- `offerings.client_id` mengacu ke `clients.client_id`.
- `offering_items.offering_id` mengacu ke `offerings.offering_id`.
- `projects.client_id` mengacu ke `clients.client_id`.
- `projects.offering_id` dapat mengacu ke `offerings.offering_id` dan boleh kosong jika proyek tidak berasal dari penawaran.
- `reports.project_id` dan `reports.client_id` dapat diisi sesuai konteks laporan.
- `document_links.document_id` mengacu ke `documents.document_id`; `entity_type` dan `entity_id` menghubungkan dokumen dengan penawaran, proyek, atau klien.

## Catatan Implementasi

Dokumen ini menjelaskan nama kolom dan fungsinya, bukan migrasi SQL final. Saat implementasi, tentukan tipe data, primary key, foreign key, constraint, indeks, serta aturan nullable/default sesuai kebutuhan aplikasi.
