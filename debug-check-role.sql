-- Script de debug pour vérifier ton rôle et les données
-- Copie ce script et exécute-le dans Supabase SQL Editor

-- 1. Vérifie ton profil et ton rôle
SELECT 
  id,
  full_name,
  role,
  status,
  created_at
FROM profiles
WHERE id = auth.uid();

-- 2. Compte les clients
SELECT 
  role,
  COUNT(*) as count
FROM profiles
GROUP BY role;

-- 3. Compte les dossiers
SELECT COUNT(*) as total_dossiers FROM dossiers;

-- 4. Vérifie si la colonne 'role' existe bien
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'role';

-- 5. Vérifie l'enum user_role
SELECT unnest(enum_range(NULL::user_role)) as role_values;
