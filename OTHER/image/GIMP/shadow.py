# -*- coding: utf-8 -*-
import gi
gi.require_version('Gimp','3.0')
gi.require_version('Gegl','0.4')
from gi.repository import Gimp, Gegl, Gio

w, h = 256, 256
inset = 24
radius = 16
sigma = 8.0
fg = Gegl.Color.new("rgba(0,0,0,0.45)")

image = Gimp.Image.new(w, h, Gimp.ImageBaseType.RGB)
layer = Gimp.Layer.new(image, "shadow", w, h,
                       Gimp.ImageType.RGBA_IMAGE, 100.0, Gimp.LayerMode.NORMAL)
image.insert_layer(layer, None, 0)
Gimp.context_set_foreground(fg)

x, y = inset, inset
iw, ih = w - 2*inset, h - 2*inset
image.select_round_rectangle(Gimp.ChannelOps.REPLACE, x, y, iw, ih, radius, radius)
layer.edit_fill(Gimp.FillType.FOREGROUND)
# 关键：放开选区，让模糊向外扩散
image.select_rectangle(Gimp.ChannelOps.REPLACE, 0, 0, w, h)

f = Gimp.DrawableFilter.new(layer, "gegl:gaussian-blur", "Blur")
cfg = f.get_config()
cfg.set_property('std-dev-x', sigma)
cfg.set_property('std-dev-y', sigma)
cfg.set_property('abyss-policy', 'clamp')
layer.append_filter(f)
layer.merge_filters()

image.select_round_rectangle(Gimp.ChannelOps.REPLACE, x, y, iw, ih, radius, radius)
layer.edit_clear()

Gimp.file_save(Gimp.RunMode.NONINTERACTIVE, image, Gio.File.new_for_path(r"E:/sd.png"), None)
