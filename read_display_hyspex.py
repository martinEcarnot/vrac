#!/usr/bin/env python3
# coding: utf-8
"""
Visualiseur d'images hyperspectrales -> RVB corrigées en réflectance
"""

import os
import time
import threading
import numpy as np
import spectral.io.envi as envi
import tkinter as tk
from tkinter import ttk, filedialog, messagebox
from matplotlib.figure import Figure
from matplotlib.backends.backend_tkagg import FigureCanvasTkAgg
import matplotlib.image as mpimg

# --- CONFIG ---
RGB_BANDS = [60, 30, 10]   # indices des bandes R, G, B
ID_SPECTRALON = 300        # largeur en colonnes utilisée pour détecter le spectralon

class HyperspectralViewer:
    def __init__(self, root):
        self.root = root
        root.title("Visualisation d'images hyperspectrales (RVB)")
        root.geometry("1000x750")

        # --- Contrôles ---
        top = ttk.Frame(root)
        top.pack(side=tk.TOP, fill=tk.X, padx=6, pady=6)

        self.btn_select = ttk.Button(top, text="Sélectionner dossier", command=self.select_folder)
        self.btn_select.pack(side=tk.LEFT)

        self.btn_prev = ttk.Button(top, text="← Précédent", command=self.show_prev, state=tk.DISABLED)
        self.btn_prev.pack(side=tk.LEFT, padx=6)

        self.btn_next = ttk.Button(top, text="Suivant →", command=self.show_next, state=tk.DISABLED)
        self.btn_next.pack(side=tk.LEFT)

        self.btn_save = ttk.Button(top, text="Enregistrer PNG", command=self.save_current, state=tk.DISABLED)
        self.btn_save.pack(side=tk.LEFT, padx=12)

        # statut + barre de progression
        self.status = ttk.Label(root, text="Aucun dossier sélectionné")
        self.status.pack(side=tk.TOP, anchor=tk.W, padx=8)

        self.progress = ttk.Progressbar(root, mode="indeterminate", length=360)
        self.progress.pack(side=tk.TOP, pady=4)

        # --- Zone d'affichage matplotlib ---
        self.fig = Figure(figsize=(8,6))
        self.ax = self.fig.add_subplot(111)
        self.ax.axis("off")
        self.canvas = FigureCanvasTkAgg(self.fig, master=root)
        self.canvas.get_tk_widget().pack(fill=tk.BOTH, expand=True, padx=6, pady=6)

        # --- Internals ---
        self.files = []
        self.index = 0
        self.cache = {}
        self.loading_thread = None

    def select_folder(self):
        folder = filedialog.askdirectory()
        if not folder:
            return
        found = []
        for f in os.listdir(folder):
            if f.lower().endswith(".hdr"):
                hdr_path = os.path.join(folder, f)
                hyspex_path = hdr_path[:-4] + ".hyspex"
                if os.path.exists(hyspex_path):
                    found.append(hdr_path)
        found.sort()
        if not found:
            messagebox.showwarning("Aucun fichier", "Aucun couple .hdr/.hyspex trouvé.")
            return
        self.files = found
        self.index = 0
        self.cache.clear()
        self.status.config(text=f"{len(self.files)} images trouvées")
        self.show_image_async()

    def show_prev(self):
        if not self.files: return
        self.index = (self.index - 1) % len(self.files)
        self.show_image_async()

    def show_next(self):
        if not self.files: return
        self.index = (self.index + 1) % len(self.files)
        self.show_image_async()

    def show_image_async(self):
        if not self.files:
            return
        hdr_file = self.files[self.index]
        title = os.path.basename(hdr_file)
        self.status.config(text=f"Préparation : {title} ({self.index+1}/{len(self.files)})")

        self.btn_select.config(state=tk.DISABLED)
        self.btn_prev.config(state=tk.DISABLED)
        self.btn_next.config(state=tk.DISABLED)
        self.btn_save.config(state=tk.DISABLED)

        if hdr_file in self.cache:
            self._display_im(self.cache[hdr_file], title)
            self._enable_buttons()
            self.status.config(text=f"{title} (cache)")
            return

        self.progress.start(10)

        def worker():
            try:
                t0 = time.time()
                hyspex_file = hdr_file[:-4] + ".hyspex"
                img_obj = envi.open(hdr_file, hyspex_file)
                arr = np.array(img_obj.load(), dtype=np.float32)  # brut
                arr = np.transpose(arr, (1, 0, 2))                # (H, W, B)

                # Extraction spectralon (zone colonnes 1..ID_SPECTRALON)
                im0 = arr[:, 1:ID_SPECTRALON, :]
                nz = np.all(im0 > 0, axis=2)  # masque pixels valides

                ref = np.zeros((arr.shape[0], arr.shape[2]), dtype=np.float32)
                for x in range(arr.shape[0]):
                    if np.any(nz[x, :]):  # éviter lignes vides
                        ref[x, :] = np.mean(im0[x, nz[x, :], :], axis=0)
                    else:
                        ref[x, :] = 1.0  # évite division par zéro

                # Extraction RVB + normalisation par spectralon
                imrgb = arr[:, :, RGB_BANDS].copy()
                for x in range(arr.shape[0]):
                    imrgb[x, :, :] = imrgb[x, :, :] / ref[x, RGB_BANDS]

                # Normalisation 0-1 pour affichage
                imrgb = np.clip(imrgb, 0, np.percentile(imrgb, 99))  # évite pixels saturés
                imrgb = (imrgb - imrgb.min()) / (imrgb.max() - imrgb.min() + 1e-6)

                elapsed = time.time() - t0
                self.root.after(0, lambda: self._on_image_loaded(hdr_file, imrgb, elapsed, None))
            except Exception as e:
                self.root.after(0, lambda: self._on_image_loaded(hdr_file, None, None, e))

        thread = threading.Thread(target=worker, daemon=True)
        thread.start()
        self.loading_thread = thread

    def _on_image_loaded(self, hdr_file, imrgb, elapsed, error):
        self.progress.stop()
        if error:
            messagebox.showerror("Erreur", f"{hdr_file}\n\n{error}")
            self.status.config(text=f"Erreur: {error}")
            self._enable_buttons(navigation=True)
            return

        self.cache[hdr_file] = imrgb
        self._display_im(imrgb, os.path.basename(hdr_file))
        self.status.config(text=f"{os.path.basename(hdr_file)} chargé en {elapsed:.1f}s")
        self._enable_buttons()

    def _display_im(self, imrgb, title=""):
        self.ax.clear()
        self.ax.axis("off")
        self.ax.imshow(imrgb)
        self.ax.set_title(title)
        self.canvas.draw_idle()

    def _enable_buttons(self, navigation=True):
        self.btn_select.config(state=tk.NORMAL)
        if navigation:
            self.btn_prev.config(state=tk.NORMAL)
            self.btn_next.config(state=tk.NORMAL)
            self.btn_save.config(state=tk.NORMAL)

    def save_current(self):
        if not self.files: return
        hdr_file = self.files[self.index]
        if hdr_file not in self.cache: return
        im = self.cache[hdr_file]
        save_path = filedialog.asksaveasfilename(defaultextension=".png",
                                                 filetypes=[("PNG", "*.png"), ("JPEG", "*.jpg;*.jpeg")],
                                                 initialfile=os.path.basename(hdr_file)[:-4] + ".png")
        if not save_path:
            return
        try:
            mpimg.imsave(save_path, np.clip(im, 0, 1))
            messagebox.showinfo("Enregistré", f"Sauvegardé : {save_path}")
        except Exception as e:
            messagebox.showerror("Erreur sauvegarde", str(e))


if __name__ == "__main__":
    root = tk.Tk()
    app = HyperspectralViewer(root)
    root.mainloop()
