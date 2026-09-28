-- ============================================================
-- RDReporta: Dominican Republic Geographic Master Data
-- 31 Provincias + 1 Distrito Nacional
-- ============================================================

CREATE TABLE IF NOT EXISTS "RdProvinces" (
    "Id" SERIAL PRIMARY KEY,
    "Name" VARCHAR(100) NOT NULL UNIQUE,
    "Region" VARCHAR(50) NOT NULL,
    "Latitude" DOUBLE PRECISION NOT NULL,
    "Longitude" DOUBLE PRECISION NOT NULL
);

INSERT INTO "RdProvinces" ("Name", "Region", "Latitude", "Longitude") VALUES
('Distrito Nacional', 'Ozama', 18.4861, -69.9312),
('Santo Domingo', 'Ozama', 18.5001, -69.8500),
('Santiago', 'Cibao Norte', 19.4517, -70.6970),
('La Vega', 'Cibao Sur', 19.2220, -70.5296),
('San Cristóbal', 'Valdesia', 18.4167, -70.1000),
('Puerto Plata', 'Cibao Norte', 19.7934, -70.6884),
('La Altagracia', 'Yuma', 18.6167, -68.7167),
('San Pedro de Macorís', 'Higuamo', 18.4539, -69.3086),
('Duarte', 'Cibao Nordeste', 19.3000, -70.2500),
('La Romana', 'Yuma', 18.4273, -68.9728),
('Espaillat', 'Cibao Norte', 19.6268, -70.2764),
('San Juan', 'El Valle', 18.8059, -71.2299),
('Peravia', 'Valdesia', 18.2796, -70.3318),
('Barahona', 'Enriquillo', 18.2085, -71.1008),
('Azua', 'Valdesia', 18.4532, -70.7349),
('Monseñor Nouel', 'Cibao Sur', 18.9467, -70.4092),
('Monte Plata', 'Higuamo', 18.8070, -69.7839),
('Sánchez Ramírez', 'Cibao Sur', 19.0528, -70.1493),
('María Trinidad Sánchez', 'Cibao Nordeste', 19.3732, -69.8523),
('Valverde', 'Cibao Noroeste', 19.5518, -70.9765),
('Hato Mayor', 'Higuamo', 18.7628, -69.2568),
('Monte Cristi', 'Cibao Noroeste', 19.8486, -71.6456),
('Samaná', 'Cibao Nordeste', 19.2056, -69.3369),
('Bahoruco', 'Enriquillo', 18.4839, -71.4194),
('Hermanas Mirabal', 'Cibao Nordeste', 19.3768, -70.4176),
('El Seibo', 'Yuma', 18.7656, -69.0389),
('San José de Ocoa', 'Valdesia', 18.5466, -70.5063),
('Dajabón', 'Cibao Noroeste', 19.5488, -71.7083),
('Santiago Rodríguez', 'Cibao Noroeste', 19.4812, -71.3394),
('Elías Piña', 'El Valle', 18.8767, -71.7031),
('Independencia', 'Enriquillo', 18.4897, -71.5178),
('Pedernales', 'Enriquillo', 18.0384, -71.7440)
ON CONFLICT ("Name") DO NOTHING;
