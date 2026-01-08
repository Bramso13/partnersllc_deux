-- Seed pour step_fields - Formulaire de Qualification LLC (Informations Personnelles)
-- step_id = 20eec50b-a1f0-46d9-a096-7c75a46cfc7b

-- ========================================
-- SECTION 1: Informations Personnelles
-- ========================================

INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, options, min_length, max_length, pattern, position, created_at, updated_at
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
  NULL,
  2,
  50,
  NULL,
  1,
  NOW(),
  NOW()
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
  NULL,
  2,
  50,
  NULL,
  2,
  NOW(),
  NOW()
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
  NULL,
  NULL,
  NULL,
  '^[^\s@]+@[^\s@]+\.[^\s@]+$',
  3,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'phone',
  'phone',
  'Téléphone',
  'Numéro de téléphone avec indicatif international',
  '+33 6 12 34 56 78',
  true,
  NULL,
  NULL,
  NULL,
  '^\+?[1-9]\d{1,14}$',
  4,
  NOW(),
  NOW()
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
  NULL,
  NULL,
  NULL,
  NULL,
  5,
  NOW(),
  NOW()
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
  '[
    {"value": "FR", "label": "Française"},
    {"value": "US", "label": "Américaine"},
    {"value": "CA", "label": "Canadienne"},
    {"value": "BE", "label": "Belge"},
    {"value": "CH", "label": "Suisse"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  6,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'ssn_or_tax_id',
  'text',
  'Numéro de Sécurité Sociale / Tax ID',
  'SSN (USA), NIR (France), ou équivalent selon votre pays',
  'XXX-XX-XXXX',
  true,
  NULL,
  9,
  20,
  NULL,
  7,
  NOW(),
  NOW()
);

-- ========================================
-- SECTION 2: Adresse Personnelle
-- ========================================

INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, options, min_length, max_length, pattern, position, created_at, updated_at
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
  NULL,
  5,
  100,
  NULL,
  8,
  NOW(),
  NOW()
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
  NULL,
  NULL,
  100,
  NULL,
  9,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'city',
  'text',
  'Ville',
  'Ville de résidence',
  'New York',
  true,
  NULL,
  2,
  50,
  NULL,
  10,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'state_province',
  'text',
  'État / Province',
  'État ou province de résidence',
  'NY',
  true,
  NULL,
  2,
  50,
  NULL,
  11,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'postal_code',
  'text',
  'Code Postal',
  'Code postal ou ZIP code',
  '10001',
  true,
  NULL,
  4,
  10,
  NULL,
  12,
  NOW(),
  NOW()
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
  '[
    {"value": "US", "label": "États-Unis"},
    {"value": "FR", "label": "France"},
    {"value": "CA", "label": "Canada"},
    {"value": "BE", "label": "Belgique"},
    {"value": "CH", "label": "Suisse"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  13,
  NOW(),
  NOW()
);

-- ========================================
-- SECTION 3: Informations sur la LLC
-- ========================================

INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, options, min_length, max_length, pattern, position, created_at, updated_at
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
  NULL,
  3,
  100,
  NULL,
  14,
  NOW(),
  NOW()
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
  NULL,
  3,
  100,
  NULL,
  15,
  NOW(),
  NOW()
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
  NULL,
  3,
  100,
  NULL,
  16,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'formation_state',
  'select',
  'État de formation',
  'L''État américain où vous souhaitez enregistrer votre LLC',
  NULL,
  true,
  '[
    {"value": "DE", "label": "Delaware"},
    {"value": "WY", "label": "Wyoming"},
    {"value": "NV", "label": "Nevada"},
    {"value": "FL", "label": "Floride"},
    {"value": "CA", "label": "Californie"},
    {"value": "TX", "label": "Texas"},
    {"value": "NY", "label": "New York"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  17,
  NOW(),
  NOW()
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
  NULL,
  NULL,
  NULL,
  18,
  NOW(),
  NOW()
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
  NULL,
  50,
  500,
  NULL,
  19,
  NOW(),
  NOW()
);

-- ========================================
-- SECTION 4: Structure de la LLC
-- ========================================

INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, options, min_length, max_length, pattern, position, created_at, updated_at
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
  '[
    {"value": "1", "label": "1 (Single-Member LLC)"},
    {"value": "2", "label": "2"},
    {"value": "3", "label": "3"},
    {"value": "4", "label": "4"},
    {"value": "5+", "label": "5+"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  20,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'ownership_percentage',
  'number',
  'Pourcentage de détention',
  'Quel pourcentage de la LLC allez-vous détenir ?',
  '100',
  true,
  NULL,
  NULL,
  NULL,
  NULL,
  21,
  NOW(),
  NOW()
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
  '[
    {"value": "DISREGARDED", "label": "Disregarded Entity (par défaut pour Single-Member)"},
    {"value": "PARTNERSHIP", "label": "Partnership (par défaut pour Multi-Member)"},
    {"value": "S_CORP", "label": "S-Corporation"},
    {"value": "C_CORP", "label": "C-Corporation"},
    {"value": "UNSURE", "label": "Je ne sais pas - conseil souhaité"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  22,
  NOW(),
  NOW()
);

-- ========================================
-- SECTION 5: Adresse Professionnelle
-- ========================================

INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, options, min_length, max_length, pattern, position, created_at, updated_at
) VALUES
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'business_address_same_as_personal',
  'radio',
  'Adresse professionnelle',
  'L''adresse professionnelle est-elle la même que votre adresse personnelle ?',
  NULL,
  true,
  '[
    {"value": "YES", "label": "Oui, utiliser mon adresse personnelle"},
    {"value": "NO", "label": "Non, j''ai une adresse différente"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  23,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'business_address_line1',
  'text',
  'Adresse professionnelle - Ligne 1',
  'Numéro et nom de rue (si différente de l''adresse personnelle)',
  NULL,
  false,
  NULL,
  NULL,
  100,
  NULL,
  24,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'business_city',
  'text',
  'Ville professionnelle',
  NULL,
  NULL,
  false,
  NULL,
  NULL,
  50,
  NULL,
  25,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'business_state',
  'text',
  'État professionnel',
  NULL,
  NULL,
  false,
  NULL,
  NULL,
  50,
  NULL,
  26,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'business_postal_code',
  'text',
  'Code postal professionnel',
  NULL,
  NULL,
  false,
  NULL,
  NULL,
  10,
  NULL,
  27,
  NOW(),
  NOW()
);

-- ========================================
-- SECTION 6: Services Additionnels
-- ========================================

INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, options, min_length, max_length, pattern, position, created_at, updated_at
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
  '[
    {"value": "YES", "label": "Oui, j''ai besoin d''un EIN"},
    {"value": "NO", "label": "Non, je l''obtiendrai moi-même"},
    {"value": "UNSURE", "label": "Je ne sais pas"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  28,
  NOW(),
  NOW()
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
  '[
    {"value": "YES", "label": "Oui, utiliser PARTNERS LLC comme Registered Agent"},
    {"value": "NO", "label": "Non, j''ai mon propre Registered Agent"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  29,
  NOW(),
  NOW()
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
  '[
    {"value": "YES", "label": "Oui, j''ai besoin d''un Operating Agreement"},
    {"value": "NO", "label": "Non, je le rédigerai moi-même"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  30,
  NOW(),
  NOW()
);

-- ========================================
-- SECTION 7: Informations Complémentaires
-- ========================================

INSERT INTO step_fields (
  id, step_id, field_key, field_type, label, description, placeholder,
  is_required, options, min_length, max_length, pattern, position, created_at, updated_at
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
  '[
    {"value": "STANDARD", "label": "Standard (2-3 semaines)"},
    {"value": "ACCELERATED", "label": "Accéléré (1 semaine)"},
    {"value": "RUSH", "label": "Rush (2-3 jours)"},
    {"value": "EXPRESS", "label": "Express (24-48h)"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  31,
  NOW(),
  NOW()
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
  '[
    {"value": "WORD_OF_MOUTH", "label": "Bouche à oreille"},
    {"value": "GOOGLE", "label": "Google / Recherche web"},
    {"value": "SOCIAL_MEDIA", "label": "Réseaux sociaux (Instagram, Facebook, etc.)"},
    {"value": "YOUTUBE", "label": "YouTube"},
    {"value": "PODCAST", "label": "Podcast"},
    {"value": "BLOG", "label": "Blog / Article"},
    {"value": "PARTNER", "label": "Recommandation d''un partenaire"},
    {"value": "AD", "label": "Publicité"},
    {"value": "OTHER", "label": "Autre"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  32,
  NOW(),
  NOW()
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
  NULL,
  NULL,
  1000,
  NULL,
  33,
  NOW(),
  NOW()
),
(
  gen_random_uuid(),
  '20eec50b-a1f0-46d9-a096-7c75a46cfc7b',
  'terms_accepted',
  'checkbox',
  'Acceptation des conditions',
  'J''accepte les conditions générales et la politique de confidentialité',
  NULL,
  true,
  '[
    {"value": "ACCEPTED", "label": "J''accepte les conditions générales et la politique de confidentialité"}
  ]'::jsonb,
  NULL,
  NULL,
  NULL,
  34,
  NOW(),
  NOW()
);

-- ========================================
-- Vérification du seed
-- ========================================

-- Compter le nombre de champs créés pour ce step
SELECT COUNT(*) as total_fields
FROM step_fields
WHERE step_id = '20eec50b-a1f0-46d9-a096-7c75a46cfc7b';

-- Voir tous les champs par ordre
SELECT position, field_key, field_type, label, is_required
FROM step_fields
WHERE step_id = '20eec50b-a1f0-46d9-a096-7c75a46cfc7b'
ORDER BY position ASC;
