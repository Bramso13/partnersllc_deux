import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { requireAuth } from "@/lib/auth";

export async function POST(request: NextRequest) {
  try {
    const user = await requireAuth();
    const supabase = await createClient();

    const formData = await request.formData();
    const file = formData.get("file") as File;
    const dossierId = formData.get("dossier_id") as string;
    const documentTypeId = formData.get("document_type_id") as string;
    const stepInstanceId = formData.get("step_instance_id") as string;

    if (!file || !dossierId || !documentTypeId) {
      return NextResponse.json(
        { error: "Missing required fields" },
        { status: 400 }
      );
    }

    // Verify dossier belongs to user
    const { data: dossier, error: dossierError } = await supabase
      .from("dossiers")
      .select("id")
      .eq("id", dossierId)
      .eq("user_id", user.id)
      .single();

    if (dossierError || !dossier) {
      return NextResponse.json(
        { error: "Dossier not found or access denied" },
        { status: 404 }
      );
    }

    // Upload file to Supabase Storage
    const fileExt = file.name.split(".").pop();
    const fileName = `${dossierId}/${documentTypeId}/${Date.now()}.${fileExt}`;

    const { data: uploadData, error: uploadError } = await supabase.storage
      .from("dossier-documents")
      .upload(fileName, file, {
        cacheControl: "3600",
        upsert: false,
      });

    if (uploadError) {
      console.error("Upload error:", uploadError);
      return NextResponse.json(
        { error: "Failed to upload file" },
        { status: 500 }
      );
    }

    // Get public URL
    const {
      data: { publicUrl },
    } = supabase.storage.from("dossier-documents").getPublicUrl(fileName);

    // Check if document already exists for this type and dossier
    const { data: existingDoc } = await supabase
      .from("documents")
      .select("id")
      .eq("dossier_id", dossierId)
      .eq("document_type_id", documentTypeId)
      .maybeSingle();

    let documentId: string;

    if (existingDoc) {
      // Update existing document
      documentId = existingDoc.id;

      // Get current version number
      const { data: versions } = await supabase
        .from("document_versions")
        .select("version_number")
        .eq("document_id", documentId)
        .order("version_number", { ascending: false })
        .limit(1);

      const nextVersion =
        versions && versions.length > 0 ? versions[0].version_number + 1 : 1;

      // Create new version
      const { data: newVersion, error: versionError } = await supabase
        .from("document_versions")
        .insert({
          document_id: documentId,
          file_url: publicUrl,
          file_name: file.name,
          file_size_bytes: file.size,
          mime_type: file.type,
          uploaded_by_type: "USER",
          uploaded_by_id: user.id,
          version_number: nextVersion,
        })
        .select()
        .single();

      if (versionError) {
        console.error("Version creation error:", versionError);
        return NextResponse.json(
          { error: "Failed to create document version" },
          { status: 500 }
        );
      }

      // Update document's current version
      await supabase
        .from("documents")
        .update({
          current_version_id: newVersion.id,
          status: "PENDING",
        })
        .eq("id", documentId);
    } else {
      // Create new document
      const { data: newDoc, error: docError } = await supabase
        .from("documents")
        .insert({
          dossier_id: dossierId,
          document_type_id: documentTypeId,
          step_instance_id: stepInstanceId || null,
          status: "PENDING",
        })
        .select()
        .single();

      if (docError) {
        console.error("Document creation error:", docError);
        return NextResponse.json(
          { error: "Failed to create document" },
          { status: 500 }
        );
      }

      documentId = newDoc.id;

      // Create first version
      const { data: newVersion, error: versionError } = await supabase
        .from("document_versions")
        .insert({
          document_id: documentId,
          file_url: publicUrl,
          file_name: file.name,
          file_size_bytes: file.size,
          mime_type: file.type,
          uploaded_by_type: "USER",
          uploaded_by_id: user.id,
          version_number: 1,
        })
        .select()
        .single();

      if (versionError) {
        console.error("Version creation error:", versionError);
        return NextResponse.json(
          { error: "Failed to create document version" },
          { status: 500 }
        );
      }

      // Update document's current version
      await supabase
        .from("documents")
        .update({ current_version_id: newVersion.id })
        .eq("id", documentId);
    }

    return NextResponse.json({
      success: true,
      document_id: documentId,
      file_url: publicUrl,
    });
  } catch (error) {
    console.error("Error in upload-document:", error);
    return NextResponse.json(
      {
        error:
          error instanceof Error ? error.message : "Failed to upload document",
      },
      { status: 500 }
    );
  }
}
