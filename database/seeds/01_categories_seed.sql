-- ============================================================
-- RDReporta: Default Categories Seed Data
-- ============================================================

INSERT INTO "Categories" ("Name", "Slug", "Description", "IconName", "ColorHex", "DisplayOrder", "IsActive", "CreatedAt")
VALUES 
('Accidentes', 'accidentes', 'Choques, colisiones o atropellamientos en vías públicas', 'car-crash', '#E53935', 1, true, NOW()),
('Tránsito', 'transito', 'Semáforos dañados, congestionamientos críticos o desvíos', 'traffic-light', '#FB8C00', 2, true, NOW()),
('Calles y Vías', 'calles-vias', 'Hoyos, derrumbes, asfaltado deteriorado o alcantarillas sin tapa', 'road', '#FDD835', 3, true, NOW()),
('Inundaciones', 'inundaciones', 'Acumulación de agua por lluvias, cañadas o ríos desbordados', 'water', '#1E88E5', 4, true, NOW()),
('Basura y Desechos', 'basura', 'Vertederos improvisados, falta de recogida o acumulación', 'trash-can', '#8E24AA', 5, true, NOW()),
('Servicios Públicos', 'servicios-publicos', 'Averías eléctricas, cortes de energía prolongados o fugas de agua', 'power-plug', '#00897B', 6, true, NOW()),
('Emergencias', 'emergencias', 'Incendios, emergencias médicas o situaciones de riesgo inminente', 'ambulance', '#D81B60', 7, true, NOW()),
('Comunidad', 'comunidad', 'Iniciativas vecinales, quejas de ruido o necesidades comunitarias', 'account-group', '#43A047', 8, true, NOW()),
('Acontecimientos', 'acontecimientos', 'Eventos locales relevantes y noticias comunitarias al momento', 'newspaper', '#3949AB', 9, true, NOW())
ON CONFLICT ("Slug") DO NOTHING;
