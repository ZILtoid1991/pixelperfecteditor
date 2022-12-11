/*
Copyright (C) 2015-2021, by Laszlo Szeremi under the Boost license.

PixelPerfectEditor
*/


module app;

import std.stdio;
import std.string;
import std.conv;
import std.format;
import std.random;

import bindbc.sdl;
//import derelict.freeimage.freeimage;

//import system.config;

import pixelperfectengine.graphics.outputscreen;
import pixelperfectengine.graphics.raster;
import pixelperfectengine.graphics.layers;

import pixelperfectengine.graphics.bitmap;

import pixelperfectengine.collision.common;
import pixelperfectengine.collision.objectcollision;

import pixelperfectengine.system.input;
import pixelperfectengine.system.file;
import pixelperfectengine.system.etc;
import pixelperfectengine.system.config;
//import pixelperfectengine.system.binarySearchTree;
import pixelperfectengine.system.common;
import core.memory;

public import editor;
//import pixelperfectengine.extbmp.extbmp;

public Editor prg;

int main(string[] args){
	initialzeSDL();
	

	prg = new Editor(args);
	prg.whereTheMagicHappens;
	return 0;
}
