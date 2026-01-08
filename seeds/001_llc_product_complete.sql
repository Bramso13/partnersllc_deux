-- =========================================================
-- SEED COMPLET: Produit LLC Formation avec Workflow
-- =========================================================
-- Crée un produit LLC avec son workflow complet :
-- - 1 Product: LLC Formation (Wyoming)
-- - 5 Steps: Qualification, Documents, Formation, EIN, Bank Account
-- - Product_Steps: Association des steps au produit
-- - Step_Fields: Champs de formulaire pour chaque step
-- =========================================================

BEGIN;

-- =========================================================
-- 1. PRODUCT: LLC Formation (Wyoming)
-- =========================================================

INSERT INTO products (
  id,
  code,
  name,
  description,
  dossier_type,
  stripe_product_id,
  stripe_price_id,
  price_amount,
  currency,
  initial_status,
  active,
  created_at,
  updated_at
) VALUES (
  '550e8400-e29b-41d4-a716-446655440001',  -- Fixed UUID pour référence
  'LLC_WY_FORMATION',
  'LLC Formation Wyoming',
  'Formation complète d''une LLC au Wyoming incluant : Enregistrement, EIN, Operating Agreement, et support pour l''ouverture de compte bancaire',
  'LLC',
  NULL,  -- À remplir avec Stripe product ID
  NULL,  -- À remplir avec Stripe price ID
  99900,  -- $999.00
  'USD',
  'QUALIFICATION',
  true,
  NOW(),
  NOW()
);

-- =========================================================
-- 2. STEPS: Définition des étapes du workflow
-- =========================================================

-- Step 1: Qualification
INSERT INTO steps (
  id,
  code,
  label,
  description,
  position,
  created_at
) VALUES (
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',  -- ID fourni par l'utilisateur
  'QUALIFICATION',
  'Qualification du projet',
  'Collecte des informations personnelles et du projet LLC',
  1,
  NOW()
);

-- Step 2: Documents
INSERT INTO steps (
  id,
  code,
  label,
  description,
  position,
  created_at
) VALUES (
  gen_random_uuid(),
  'DOCUMENTS',
  'Documents requis',
  'Upload des documents d''identité et justificatifs',
  2,
  NOW()
);

-- Step 3: Formation
INSERT INTO steps (
  id,
  code,
  label,
  description,
  position,
  created_at
) VALUES (
  gen_random_uuid(),
  'FORMATION',
  'Formation de la LLC',
  'Traitement de l''enregistrement de la LLC au Wyoming',
  3,
  NOW()
);

-- Step 4: EIN
INSERT INTO steps (
  id,
  code,
  label,
  description,
  position,
  created_at
) VALUES (
  gen_random_uuid(),
  'EIN',
  'Obtention de l''EIN',
  'Demande de l''Employer Identification Number (EIN) auprès de l''IRS',
  4,
  NOW()
);

-- Step 5: Bank Account
INSERT INTO steps (
  id,
  code,
  label,
  description,
  position,
  created_at
) VALUES (
  gen_random_uuid(),
  'BANK_ACCOUNT',
  'Ouverture compte bancaire',
  'Préparation et support pour l''ouverture du compte bancaire US',
  5,
  NOW()
);

-- =========================================================
-- 3. PRODUCT_STEPS: Association des steps au produit LLC
-- =========================================================

INSERT INTO product_steps (
  id,
  product_id,
  step_id,
  position,
  is_required,
  estimated_duration_hours,
  created_at
)
SELECT
  gen_random_uuid(),
  '550e8400-e29b-41d4-a716-446655440001',  -- LLC Product ID
  s.id,
  s.position,
  true,  -- Tous les steps sont requis
  CASE s.code
    WHEN 'QUALIFICATION' THEN 1
    WHEN 'DOCUMENTS' THEN 2
    WHEN 'FORMATION' THEN 72  -- 3 jours
    WHEN 'EIN' THEN 48  -- 2 jours
    WHEN 'BANK_ACCOUNT' THEN 24  -- 1 jour
  END,
  NOW()
FROM steps s
WHERE s.code IN ('QUALIFICATION', 'DOCUMENTS', 'FORMATION', 'EIN', 'BANK_ACCOUNT')
ORDER BY s.position;

-- =========================================================
-- 4. STEP_FIELDS: Champs du formulaire de QUALIFICATION
-- =========================================================

-- SECTION 1: Informations Personnelles
INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, min_length, max_length, min_value, max_value, pattern, options,
  help_text, default_value, position, created_at, updated_at
) VALUES
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'first_name',
  'text',
  'Prénom',
  'Votre prénom légal tel qu''il apparaît sur vos documents officiels',
  'John',
  true,
  2, 50, NULL, NULL, NULL, NULL,
  'Ce nom apparaîtra sur les documents officiels de votre LLC',
  NULL,
  1,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'last_name',
  'text',
  'Nom',
  'Votre nom de famille légal',
  'Doe',
  true,
  2, 50, NULL, NULL, NULL, NULL,
  'Votre nom de famille tel qu''il apparaît sur vos pièces d''identité',
  NULL,
  2,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'email',
  'email',
  'Email',
  'Adresse email principale pour toutes les communications',
  'john.doe@example.com',
  true,
  NULL, NULL, NULL, NULL, '^[^\s@]+@[^\s@]+\.[^\s@]+$', NULL,
  'Nous utiliserons cet email pour toutes les communications importantes',
  NULL,
  3,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'phone',
  'text',
  'Téléphone',
  'Numéro de téléphone avec indicatif international',
  '+33 6 12 34 56 78',
  true,
  NULL, NULL, NULL, NULL, '^\+?[1-9]\d{1,14}$', NULL,
  'Format international recommandé (ex: +33612345678)',
  NULL,
  4,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'date_of_birth',
  'date',
  'Date de naissance',
  'Vous devez avoir au moins 18 ans pour créer une LLC',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL, NULL,
  'Requis pour vérifier que vous êtes majeur',
  NULL,
  5,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'nationality',
  'select',
  'Nationalité',
  'Votre nationalité actuelle',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "FR", "label": "Française"},
    {"value": "US", "label": "Américaine"},
    {"value": "CA", "label": "Canadienne"},
    {"value": "BE", "label": "Belge"},
    {"value": "CH", "label": "Suisse"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  NULL, NULL,
  6,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'ssn_or_tax_id',
  'text',
  'Numéro de Sécurité Sociale / Tax ID',
  'SSN (USA), NIR (France), ou équivalent selon votre pays',
  NULL,
  true,
  9, 20, NULL, NULL, NULL, NULL,
  'Requis pour l''obtention de l''EIN',
  NULL,
  7,
  NOW(), NOW()
);

-- SECTION 2: Adresse Personnelle
INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, min_length, max_length, min_value, max_value, pattern, options,
  help_text, default_value, position, created_at, updated_at
) VALUES
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'address_line1',
  'text',
  'Adresse - Ligne 1',
  'Numéro et nom de rue',
  '123 Main Street',
  true,
  5, 100, NULL, NULL, NULL, NULL,
  'Votre adresse de résidence actuelle',
  NULL,
  8,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'address_line2',
  'text',
  'Adresse - Ligne 2',
  'Appartement, bureau, bâtiment (optionnel)',
  'Apt 4B',
  false,
  NULL, 100, NULL, NULL, NULL, NULL,
  NULL, NULL,
  9,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'city',
  'text',
  'Ville',
  'Ville de résidence',
  'Paris',
  true,
  2, 50, NULL, NULL, NULL, NULL,
  NULL, NULL,
  10,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'state_province',
  'text',
  'État / Province / Région',
  'État ou province de résidence',
  'Île-de-France',
  true,
  2, 50, NULL, NULL, NULL, NULL,
  NULL, NULL,
  11,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'postal_code',
  'text',
  'Code Postal',
  'Code postal ou ZIP code',
  '75001',
  true,
  4, 10, NULL, NULL, NULL, NULL,
  NULL, NULL,
  12,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'country',
  'select',
  'Pays',
  'Pays de résidence',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "US", "label": "États-Unis"},
    {"value": "FR", "label": "France"},
    {"value": "CA", "label": "Canada"},
    {"value": "BE", "label": "Belgique"},
    {"value": "CH", "label": "Suisse"},
    {"value": "GB", "label": "Royaume-Uni"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  NULL, NULL,
  13,
  NOW(), NOW()
);

-- SECTION 3: Informations sur la LLC
INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, min_length, max_length, min_value, max_value, pattern, options,
  help_text, default_value, position, created_at, updated_at
) VALUES
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'company_name',
  'text',
  'Nom de l''entreprise souhaité',
  'Le nom que vous souhaitez donner à votre LLC',
  'My Business LLC',
  true,
  3, 100, NULL, NULL, NULL, NULL,
  'Le nom doit se terminer par "LLC" ou "L.L.C."',
  NULL,
  14,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'company_name_alt1',
  'text',
  'Nom alternatif 1',
  'Premier choix de secours si le nom principal n''est pas disponible',
  NULL,
  false,
  3, 100, NULL, NULL, NULL, NULL,
  'Nous vérifierons la disponibilité du nom auprès du Wyoming',
  NULL,
  15,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'company_name_alt2',
  'text',
  'Nom alternatif 2',
  'Deuxième choix de secours',
  NULL,
  false,
  3, 100, NULL, NULL, NULL, NULL,
  NULL, NULL,
  16,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'business_type',
  'select',
  'Type d''activité',
  'Secteur principal de votre activité',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "ECOMMERCE", "label": "E-commerce"},
    {"value": "DIGITAL_SERVICES", "label": "Services Numériques"},
    {"value": "CONSULTING", "label": "Consulting"},
    {"value": "REAL_ESTATE", "label": "Immobilier"},
    {"value": "TRADING", "label": "Trading / Investissement"},
    {"value": "MARKETING", "label": "Marketing Digital"},
    {"value": "SAAS", "label": "SaaS / Logiciel"},
    {"value": "IMPORT_EXPORT", "label": "Import / Export"},
    {"value": "DROPSHIPPING", "label": "Dropshipping"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  'Cela nous aide à vous fournir les meilleurs conseils',
  NULL,
  17,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'business_description',
  'textarea',
  'Description de l''activité',
  'Décrivez brièvement l''activité que vous allez exercer avec cette LLC',
  NULL,
  true,
  50, 500, NULL, NULL, NULL, NULL,
  'Cette description apparaîtra dans vos documents de formation',
  NULL,
  18,
  NOW(), NOW()
);

-- SECTION 4: Structure de la LLC
INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, min_length, max_length, min_value, max_value, pattern, options,
  help_text, default_value, position, created_at, updated_at
) VALUES
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'number_of_members',
  'select',
  'Nombre de membres',
  'Combien de personnes détiendront des parts de la LLC ?',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "1", "label": "1 (Single-Member LLC)"},
    {"value": "2", "label": "2"},
    {"value": "3", "label": "3"},
    {"value": "4", "label": "4"},
    {"value": "5", "label": "5 ou plus"}
  ]'::jsonb,
  'Affecte la structure fiscale et l''Operating Agreement',
  NULL,
  19,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'ownership_percentage',
  'number',
  'Votre pourcentage de détention',
  'Quel pourcentage de la LLC allez-vous détenir ?',
  '100',
  true,
  NULL, NULL, 1, 100, NULL, NULL,
  'Doit être entre 1 et 100',
  '100',
  20,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'tax_classification',
  'select',
  'Classification fiscale souhaitée',
  'Comment souhaitez-vous que votre LLC soit imposée ?',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "DISREGARDED", "label": "Disregarded Entity (par défaut pour Single-Member)"},
    {"value": "PARTNERSHIP", "label": "Partnership (par défaut pour Multi-Member)"},
    {"value": "S_CORP", "label": "S-Corporation"},
    {"value": "C_CORP", "label": "C-Corporation"},
    {"value": "UNSURE", "label": "Je ne sais pas - conseil souhaité"}
  ]'::jsonb,
  'Nous vous conseillerons sur la meilleure option pour votre situation',
  NULL,
  21,
  NOW(), NOW()
);

-- SECTION 5: Services Additionnels
INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, min_length, max_length, min_value, max_value, pattern, options,
  help_text, default_value, position, created_at, updated_at
) VALUES
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'ein_needed',
  'radio',
  'Besoin d''un EIN (Employer Identification Number) ?',
  'L''EIN est nécessaire pour ouvrir un compte bancaire US',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "YES", "label": "Oui, j''ai besoin d''un EIN"},
    {"value": "NO", "label": "Non, je l''obtiendrai moi-même"},
    {"value": "UNSURE", "label": "Je ne sais pas"}
  ]'::jsonb,
  'Nous recommandons fortement de prendre notre service EIN',
  'YES',
  22,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'registered_agent_service',
  'radio',
  'Service de Registered Agent',
  'Un Registered Agent est obligatoire. Souhaitez-vous notre service ?',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "YES", "label": "Oui, utiliser PARTNERS LLC comme Registered Agent"},
    {"value": "NO", "label": "Non, j''ai mon propre Registered Agent"}
  ]'::jsonb,
  'Le Registered Agent reçoit les documents légaux pour votre LLC',
  'YES',
  23,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'operating_agreement',
  'radio',
  'Operating Agreement',
  'Document interne définissant les règles de fonctionnement de la LLC',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "YES", "label": "Oui, j''ai besoin d''un Operating Agreement"},
    {"value": "NO", "label": "Non, je le rédigerai moi-même"}
  ]'::jsonb,
  'Fortement recommandé, même pour les Single-Member LLC',
  'YES',
  24,
  NOW(), NOW()
);

-- SECTION 6: Informations Complémentaires
INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, min_length, max_length, min_value, max_value, pattern, options,
  help_text, default_value, position, created_at, updated_at
) VALUES
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'urgency_level',
  'select',
  'Niveau d''urgence',
  'Dans quel délai souhaitez-vous que votre LLC soit créée ?',
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "STANDARD", "label": "Standard (2-3 semaines)"},
    {"value": "ACCELERATED", "label": "Accéléré (1 semaine)"},
    {"value": "RUSH", "label": "Rush (2-3 jours)"},
    {"value": "EXPRESS", "label": "Express (24-48h)"}
  ]'::jsonb,
  'Les options accélérées entraînent des frais supplémentaires',
  'STANDARD',
  25,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'how_did_you_hear',
  'select',
  'Comment avez-vous entendu parler de nous ?',
  'Cela nous aide à améliorer nos services',
  NULL,
  false,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "WORD_OF_MOUTH", "label": "Bouche à oreille"},
    {"value": "GOOGLE", "label": "Google / Recherche web"},
    {"value": "SOCIAL_MEDIA", "label": "Réseaux sociaux"},
    {"value": "YOUTUBE", "label": "YouTube"},
    {"value": "PODCAST", "label": "Podcast"},
    {"value": "BLOG", "label": "Blog / Article"},
    {"value": "PARTNER", "label": "Recommandation d''un partenaire"},
    {"value": "AD", "label": "Publicité"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  NULL, NULL,
  26,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'additional_notes',
  'textarea',
  'Notes additionnelles',
  'Questions, demandes spéciales, ou informations complémentaires',
  NULL,
  false,
  NULL, 1000, NULL, NULL, NULL, NULL,
  'Partagez tout ce qui pourrait nous aider à mieux vous servir',
  NULL,
  27,
  NOW(), NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'terms_accepted',
  'checkbox',
  'Acceptation des conditions',
  NULL,
  NULL,
  true,
  NULL, NULL, NULL, NULL, NULL,
  '[
    {"value": "ACCEPTED", "label": "J''accepte les conditions générales et la politique de confidentialité"}
  ]'::jsonb,
  'Vous devez accepter pour continuer',
  NULL,
  28,
  NOW(), NOW()
);

-- =========================================================
-- VÉRIFICATIONS
-- =========================================================

-- Vérifier le produit créé
SELECT * FROM products WHERE code = 'LLC_WY_FORMATION';

-- Compter les steps créés
SELECT COUNT(*) as total_steps FROM steps;

-- Vérifier l'association product_steps
SELECT
  ps.position,
  s.code,
  s.label,
  ps.estimated_duration_hours
FROM product_steps ps
JOIN steps s ON ps.step_id = s.id
WHERE ps.product_id = '550e8400-e29b-41d4-a716-446655440001'
ORDER BY ps.position;

-- Compter les champs du formulaire de qualification
SELECT COUNT(*) as total_fields
FROM step_fields
WHERE step_id = '20eec50b-a1f0-46d9-a096-7c75a46cfc7b';

-- Lister tous les champs par ordre
SELECT
  position,
  field_key,
  field_type,
  label,
  is_required
FROM step_fields
WHERE step_id = '20eec50b-a1f0-46d9-a096-7c75a46cfc7b'
ORDER BY position ASC;

COMMIT;

-- =========================================================
-- NOTES
-- =========================================================
-- Ce seed crée :
-- - 1 produit LLC (Wyoming) à $999
-- - 5 steps de workflow
-- - 5 product_steps associés
-- - 28 champs de formulaire pour le step Qualification
--
-- Pour les autres steps (Documents, Formation, EIN, Bank Account),
-- vous devrez créer leurs step_fields respectifs selon vos besoins.
-- =========================================================
