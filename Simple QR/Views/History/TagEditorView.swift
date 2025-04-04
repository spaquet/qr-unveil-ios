//
//  TagEditorView.swift
//  Simple QR
//
//  Created by Stéphane PAQUET on 4/4/25.
//

import SwiftUI
import SwiftData

/// A view for creating or editing tags
struct TagEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    // State for editing
    @State private var tagName: String = ""
    @State private var selectedColor: String = TagModel.randomColor()
    @State private var showingError = false
    @State private var errorMessage = ""
    
    // For editing mode
    var editingTag: TagModel? = nil
    
    // Use ColorUtility for predefined colors
    private let colorOptions = [
        "#FF5733", // Red-Orange
        "#33FF57", // Green
        "#3357FF", // Blue
        "#FF33A8", // Pink
        "#33FFF0", // Cyan
        "#F033FF", // Magenta
        "#FF8333", // Orange
        "#33FF83", // Mint
        "#8333FF", // Purple
        "#FFCE33", // Yellow
        "#33B5FF", // Light Blue
        "#FF33B5"  // Rose
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                // Tag name section
                Section("Tag Name") {
                    TextField("Name", text: $tagName)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.words)
                }
                
                // Color selection section
                Section("Tag Color") {
                    LazyVGrid(columns: [
                        GridItem(.adaptive(minimum: 44), spacing: 12)
                    ], spacing: 12) {
                        ForEach(colorOptions, id: \.self) { color in
                            ColorCircle(
                                color: ColorUtility.color(from: color),
                                isSelected: selectedColor == color
                            )
                            .onTapGesture {
                                selectedColor = color
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle(editingTag == nil ? "New Tag" : "Edit Tag")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTag()
                    }
                    .disabled(tagName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .onAppear {
                // If editing, load existing values
                if let tag = editingTag {
                    tagName = tag.name
                    selectedColor = tag.color ?? TagModel.randomColor()
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
    }
    
    // Save the tag to the database
    private func saveTag() {
        let trimmedName = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedName.isEmpty else {
            showError("Tag name cannot be empty.")
            return
        }
        
        do {
            if let existingTag = editingTag {
                // Update existing tag
                existingTag.updateName(trimmedName)
                existingTag.updateColor(selectedColor)
            } else {
                // Create new tag
                let newTag = TagModel(name: trimmedName, color: selectedColor)
                modelContext.insert(newTag)
            }
            
            try modelContext.save()
            dismiss()
        } catch {
            showError("Failed to save tag: \(error.localizedDescription)")
        }
    }
    
    private func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
}

// MARK: - Helper Components

/// Color selection circle
struct ColorCircle: View {
    let color: Color
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 44, height: 44)
                .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
            
            if isSelected {
                Circle()
                    .strokeBorder(Color.white, lineWidth: 3)
                    .frame(width: 44, height: 44)
                
                Image(systemName: "checkmark")
                    .foregroundColor(.white)
                    .font(.system(size: 16, weight: .bold))
                    .shadow(color: .black.opacity(0.5), radius: 1, x: 0, y: 0)
            }
        }
    }
}

#Preview {
    TagEditorView()
        .modelContainer(for: TagModel.self, inMemory: true)
}
