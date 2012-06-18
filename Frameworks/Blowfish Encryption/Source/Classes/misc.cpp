// Copyright (c) 2005 - 2010 Mathias Karlsson
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Please see License.txt for further information.

#include "misc.hpp"

using namespace std;

string base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

string itos(int i, const int base)
{
	if (base < 2 || base > 10 + 'Z' - 'A' + 1) return "";
	string pre;
	string s;
	if (i < 0) {
		pre = "-";
		i = 0 - i;
	}
	do {
		int digit = i % base;
		char ch = digit > 9 ? 'A' + digit - 10 : '0' + digit;
		s.insert((string::size_type)0, (string::size_type)1, (char)ch);
		i /= base;
	} while (i != 0);
	return pre + s;
}

int stoi(const string &s, const int base)
{
	if (s.empty()) return 0;
	if (base < 2 || base > 10 + 'Z' - 'A' + 1) return 0;
	bool minus = false;
	int i = 0;
	string::size_type idx = 0;
	if (s[0] == '-') minus = true;
	if (s[0] == '-' || s[0] == '+') idx++;
	for (; idx < s.size(); idx++) {
		int ch = tolower(s[idx]);
		if (ch >= 'a' && ch <= 'z' && base > 10 + ch - 'a') {
			i = i * base + 10 + ch - 'a';
		} else if (ch >= '0' && ch <= '9' && base > ch - '0') {
			i = i * base + ch - '0';
		} else {
			break;
		}
	}
	return minus ? 0 - i : i;
}

void tokenize(const string &s, const string delim, vector<string> &v)
{
	v.clear();
	if (delim.empty() || s.empty()) return;
	string::size_type pos = 0, start = 0;
	do {
		pos = s.find(delim, start);
		v.push_back(s.substr(start, pos - start));
		start = pos + delim.size();
	} while (pos != string::npos);
}

int numtok(const string &s, const string delim)
{
	if (delim.empty() || s.empty()) return 0;
	string::size_type pos = 0, start = 0;
	int cnt = 0;
	do {
		pos = s.find(delim, start);
		cnt++;
		start = pos + delim.size();
	} while (pos != string::npos);
	return cnt;
}

string gettok(const string &s, const string delim, const int index)
{
	string empty;
	if (delim.empty() || s.empty()) return empty;
	string::size_type pos = 0, start = 0;
	int cnt = 0;
	do {
		pos = s.find(delim, start);
		cnt++;
		if (index == cnt - 1) return s.substr(start, pos - start);
		start = pos + delim.size();
	} while (pos != string::npos);
	return empty;
}

string lowercase(string s)
{
	string::size_type i;
	for (i = 0; i < s.size(); i++) s[i] = (char)tolower(s[i]);
	return s;
}

string uppercase(string s)
{
	string::size_type i;
	for (i = 0; i < s.size(); i++) s[i] = (char)toupper(s[i]);
	return s;
}

string pop_word_front(string &str)
{
	string::size_type spacepos = str.find(' ');
	string w;
	if (spacepos == string::npos) {
		w.swap(str);
	} else {
		w = str.substr(0, spacepos);
		str.erase(0, spacepos + 1);
	}
	return w;
}

void remove_chars(string &str, const string chars)
{
	string::size_type i;
	while (i = str.find_first_of(chars), i != string::npos) str.erase(i, 1);
}

void remove_bad_chars(string &str)
{
	string::size_type i;
	while (i = str.find('\x00', 0), i != string::npos) str.erase(i, 1);
	while (i = str.find_first_of("\x0d\x0a"), i != string::npos) str.erase(i, 1);
}

void addtab(string &s, string add, const int len, const char fillchar)
{
	add.resize(len, fillchar);
	s += add;
}

void addtab(string &s, int add, const int len, const char fillchar)
{
	string add_str = itos(add);
	add_str.resize(len, fillchar);
	s += add_str;
}

void base64encode(string src, string &dest)
{
	string::size_type size = src.size();
	src.resize(size + (3 - (size % 3)), 0);
	dest.erase();
	unsigned long data;
	unsigned char *p = (unsigned char *)src.data();
	for (string::size_type i = 0; i < size; i += 3) {
		data = *p++ << 16;
		data += *p++ << 8;
		data += *p++;
		for (int part = 0; part < 4; part++) {
			if (part >= 2 && i + part > size) {
				dest += "=";
			} else {
				dest += base64[(data >> 18) & 63];
			}
			data = data << 6;
		}
	}
}

void base64decode(string src, string &dest)
{
	dest.erase();
	if (src.find_first_not_of(base64 + "=") != string::npos) return;
	if (src.size() % 4 != 0) return;
	unsigned long data = 0, val;
	char *p = (char *)src.data();
	for (string::size_type i = 0; i < src.size(); i += 4) {
		if ((val = base64.find(*p++)) != string::npos) data = val << 18;
		if ((val = base64.find(*p++)) != string::npos) data += val << 12;
		if ((val = base64.find(*p++)) != string::npos) data += val << 6;
		if ((val = base64.find(*p++)) != string::npos) data += val;
		dest += (data >> 16) & 255;
		if (src[i + 2] != '=') dest += (data >> 8) & 255;
		if (src[i + 3] != '=') dest += data & 255;
	}
}