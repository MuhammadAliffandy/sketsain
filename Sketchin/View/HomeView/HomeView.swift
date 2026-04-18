//
//  HomeView.swift
//  Sketchin
//
//  Created by Muhammad Aliffandy on 10/04/26.
//

import SwiftUI
import UIKit

struct HomeView: View {
    
    // --- 1. GENERAL STATES ---
    @State private var exploreSearchQuery: String = ""
    @State private var isMenuOpen: Bool = false
    @State private var isShowingGallery: Bool = false
    
    // --- 2. SELECTION MODE STATES ---
    @State private var isSelectionMode: Bool = false
    @State private var selectedItems: Set<Int> = []
    
    // --- 3. RENAME FEATURE STATES ---
    // Menyimpan 10 judul default awal
    @State private var itemTitles: [String] = (0..<10).map { "Title \($0)" }
    @State private var editingIndex: Int? = nil
    @FocusState private var isTextFieldFocused: Bool
    
    let fourColumn = Array(repeating: GridItem(.flexible(), spacing: 30), count: 4)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // ==========================================
                // BAGIAN 1: CUSTOM HEADER AREA (iOS 26 Style)
                // ==========================================
                VStack(alignment: .leading, spacing: 20) {
                    
                    // BARIS ATAS: Tombol dinamis berdasarkan Mode
                    HStack {
                        if isSelectionMode {
                            // --- MODE SELECT: Tombol Batal (Kiri) ---
                            UIKitCircleButton(
                                iconName: "xmark",
                                bgColor: .systemGray4,
                                tintColor: .black,
                                hasShadow: false,
                                action: {
                                    withAnimation(.spring()) {
                                        isSelectionMode = false
                                        selectedItems.removeAll()
                                    }
                                }
                            )
                            .frame(width: 45, height: 45)
                            
                        } else {
                            // --- MODE NORMAL: Tombol Menu (Kiri) ---
                            UIKitCircleButton(
                                iconName: "line.3.horizontal",
                                bgColor: .white,
                                tintColor: .black,
                                hasShadow: true,
                                action: { isMenuOpen.toggle() }
                            )
                            .frame(width: 45, height: 45)
                            // Popover Menu nempel di tombol
                            .popover(isPresented: $isMenuOpen, arrowEdge: .top) {
                                VStack(alignment: .leading, spacing: 30) {
                                    Button(action: {
                                        isMenuOpen = false
                                        withAnimation(.spring()) {
                                            isSelectionMode = true
                                        }
                                    }) {
                                        Label("Select", systemImage: "checkmark.circle")
                                            .foregroundColor(.primary)
                                    }
                                    
                                    Button(action: {
                                        print("App closing...")
                                        exit(0) // Menutup aplikasi (Testing only)
                                    }) {
                                        Label("Close App", systemImage: "xmark.circle")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(20)
                                .frame(width: 200)
                                .presentationCornerRadius(15)
                            }
                        }
                        
                        Spacer()
                        
                        if isSelectionMode {
                            // --- MODE SELECT: Tombol Hapus/Trash (Kanan) ---
                            let hasSelection = !selectedItems.isEmpty
                            UIKitCircleButton(
                                iconName: "trash",
                                // Menyala merah jika ada yang dipilih
                                bgColor: hasSelection ? .systemRed : .systemGray4,
                                tintColor: hasSelection ? .white : .gray,
                                hasShadow: hasSelection,
                                action: {
                                    if hasSelection {
                                        print("Menghapus item: \(selectedItems)")
                                        withAnimation(.spring()) {
                                            isSelectionMode = false
                                            selectedItems.removeAll()
                                        }
                                    }
                                }
                            )
                            .frame(width: 45, height: 45)
                            
                        } else {
                            // --- MODE NORMAL: Tombol Tambah/Plus (Kanan) ---
                            UIKitCircleButton(
                                iconName: "plus",
                                bgColor: .systemBlue,
                                tintColor: .white,
                                hasShadow: true,
                                action: { isShowingGallery = true }
                            )
                            .frame(width: 45, height: 45)
                        }
                    }
                    
                    // BARIS TENGAH: Judul Dinamis
                    Text(isSelectionMode ? "\(selectedItems.count) Selected" : "Gallery")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundColor(.black)
                    
                    // BARIS BAWAH: Search Bar (Sembunyi saat mode Select)
                    if !isSelectionMode {
                        UIKitSearchBar(
                            text: $exploreSearchQuery,
                            onMicTapped: { print("Mic tapped") }
                        )
                        .frame(height: 50)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 20)
                .background(Color(UIColor.systemGroupedBackground))
                
                // ==========================================
                // BAGIAN 2: SCROLLABLE CONTENT (GRID AREA)
                // ==========================================
                ScrollView {
                    LazyVGrid(columns: fourColumn, spacing: 30) {
                        ForEach(0..<10, id: \.self) { index in
                            
                            ZStack {
                                // 2A. KARTU GAMBAR & TEKS
                                VStack {
                                    Rectangle()
                                        .fill(Color.gray.opacity(0.3))
                                        .aspectRatio(1, contentMode: .fit)
                                        .cornerRadius(10)
                                    
                                    // Logika Ganti Nama (Rename)
                                    if editingIndex == index {
                                        TextField("Masukkan judul", text: $itemTitles[index])
                                            .font(.headline)
                                            .multilineTextAlignment(.center)
                                            .focused($isTextFieldFocused)
                                            .onSubmit { editingIndex = nil }
                                            .padding(4)
                                            .background(Color.gray.opacity(0.1))
                                            .cornerRadius(5)
                                    } else {
                                        Text(itemTitles[index])
                                            .font(.headline)
                                            // Klik ganda untuk memunculkan keyboard
                                            .onTapGesture(count: 2) {
                                                if !isSelectionMode {
                                                    editingIndex = index
                                                    isTextFieldFocused = true
                                                }
                                            }
                                    }
                                    
                                    Text("Subtitle")
                                        .font(.subheadline)
                                        .foregroundColor(.gray)
                                }
                                // Meredupkan kartu jika mode select aktif tapi tidak dipilih
                                .opacity(isSelectionMode && !selectedItems.contains(index) ? 0.6 : 1.0)
                                
                                // 2B. INDIKATOR LINGKARAN PILIHAN (Tengah)
                                if isSelectionMode {
                                    let isSelected = selectedItems.contains(index)
                                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                        .font(.system(size: 34, weight: .regular))
                                        .foregroundColor(isSelected ? .blue : .white)
                                        .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                                        .scaleEffect(isSelected ? 1.15 : 1.0)
                                }
                            }
                            // 2C. GESTUR KLIK SEKALI PADA KARTU
                            .onTapGesture(count: 1) {
                                if editingIndex != nil {
                                    // Jika sedang mengetik, klik di luar akan menutup keyboard
                                    editingIndex = nil
                                } else if isSelectionMode {
                                    // Logika memih item saat mode Select
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                        if selectedItems.contains(index) {
                                            selectedItems.remove(index)
                                        } else {
                                            selectedItems.insert(index)
                                        }
                                    }
                                } else {
                                    // Buka file saat mode normal
                                    print("Membuka Sketsa nomor \(index)")
                                }
                            }
                            
                        }
                    }
                    .padding(20)
                }
                .background(Color(UIColor.systemGroupedBackground))
            }
            .navigationBarHidden(true)
        }
    }
}


#Preview {
    HomeView()
}
