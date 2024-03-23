const std = @import("std");

const fmt = std.fmt;

pub const Type = enum {
    // pairs
    LFT_PAREN,
    RGT_PAREN,

    LFT_BRACE,
    RGT_BRACE,

    // single char token
    COMMA,
    DOT,
    PLUS,
    MINUS,
    SEMICOLON,
    SLASH,
    STAR,

    // one-two char token
    BANG,
    BANG_EQUAL,

    EQUAL,
    EQUAL_EQUAL,

    GREATER,
    GREATER_EQUAL,

    LESSER,
    LESSER_EQUAL,

    // literals
    STRING,
    NUMBER,
    IDENTIFIER,

    // keywords
    AND,
    CLASS,
    ELSE,
    FALSE,
    FUN,
    FOR,
    IF,
    NIL,
    OR,
    PRINT,
    RETURN,
    SUPER,
    THIS,
    TRUE,
    VAR,
    WHILE,

    EOF,
};

pub const List = std.ArrayList(Token);

pub const Literal = union {
    identifier: []const u8,
    string: []const u8,
    number: f32,
};

pub const Token = struct {
    type: Type,
    lexeme: []const u8,
    line: usize,

    literal: ?Literal,
    pub fn format(self: Token, _: []const u8, _: fmt.FormatOptions, writer: anytype) !void {
        _ = try fmt.format(writer, "[{s}", .{@tagName(self.type)});

        switch (self.type) {
            Type.STRING => _ = try fmt.format(writer, " \"{s}\"", .{self.literal.?.string}),
            Type.NUMBER => _ = try fmt.format(writer, " {d}", .{self.literal.?.number}),
            Type.IDENTIFIER => _ = try fmt.format(writer, " {s} ", .{self.literal.?.identifier}),
            else => {},
        }

        _ = try fmt.format(writer, "]", .{});
    }
};
