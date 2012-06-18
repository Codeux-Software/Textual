// Copyright (c) 2005 - 2010 Mathias Karlsson
//
// This program is free software; you can redistribute it and/or
// modify it under the terms of the GNU General Public License
// as published by the Free Software Foundation; either version 2
// of the License, or (at your option) any later version.
//
// Please see License.txt for further information.

#include <string>
#include <vector>

extern std::string base64;

std::string itos(int i, const int base = 10);
int stoi(const std::string &s, const int base = 10);

void tokenize(const std::string &s, const std::string delim, std::vector<std::string> &v);
int numtok(const std::string &s, const std::string delim);
std::string gettok(const std::string &s, const std::string delim, const int index);

std::string lowercase(std::string s);
std::string uppercase(std::string s);

std::string pop_word_front(std::string &str);
void remove_chars(std::string &str, const std::string chars);
void remove_bad_chars(std::string &str);

void addtab(std::string &s, std::string add, const int len, const char fillchar = ' ');
void addtab(std::string &s, int add, const int len, const char fillchar = ' ');

void base64encode(std::string src, std::string &dest);
void base64decode(std::string src, std::string &dest);