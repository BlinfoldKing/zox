const std = @import("std");
const token = @import("token.zig");

pub const Error = error{
    INVALID_TOKEN,
    UNTERMINATED_STRING,
};

pub const Scanner = struct {
    source: []const u8,
    start: usize,
    current: usize,

    line: u32,
    col: u32,

    fn is_end(self: Scanner) bool {
        return self.current >= self.source.len;
    }

    fn peek(self: Scanner) u8 {
        if (self.is_end()) return 0;
        return self.source[self.current];
    }

    fn peek_next(self: Scanner) u8 {
        if (self.current + 1 >= self.source.len) return 0;
        return self.source[self.current + 1];
    }

    fn match(self: *Scanner, char: u8) bool {
        if (self.peek() != char) return false;

        self.next();
        return true;
    }

    fn advance(self: *Scanner) u8 {
        const res = self.peek();
        self.next();
        return res;
    }

    pub fn scan(self: *Scanner, allocator: std.mem.Allocator) !token.List {
        var arena = std.heap.ArenaAllocator.init(allocator);
        defer arena.deinit();

        var res: token.List = token.List.init(arena.allocator());
        defer res.deinit();

        var reserved_keyword = std.StringHashMap(token.Type).init(allocator);
        _ = try reserved_keyword.put("and", token.Type.AND);
        _ = try reserved_keyword.put("class", token.Type.CLASS);
        _ = try reserved_keyword.put("else", token.Type.ELSE);
        _ = try reserved_keyword.put("false", token.Type.FALSE);
        _ = try reserved_keyword.put("fun", token.Type.FUN);
        _ = try reserved_keyword.put("for", token.Type.FOR);
        _ = try reserved_keyword.put("if", token.Type.IF);
        _ = try reserved_keyword.put("nil", token.Type.NIL);
        _ = try reserved_keyword.put("or", token.Type.OR);
        _ = try reserved_keyword.put("print", token.Type.PRINT);
        _ = try reserved_keyword.put("return", token.Type.RETURN);
        _ = try reserved_keyword.put("super", token.Type.SUPER);
        _ = try reserved_keyword.put("this", token.Type.THIS);
        _ = try reserved_keyword.put("true", token.Type.TRUE);
        _ = try reserved_keyword.put("var", token.Type.VAR);
        _ = try reserved_keyword.put("while", token.Type.WHILE);

        while (!self.is_end()) {
            self.start = self.current;
            const char = self.advance();

            switch (char) {
                '(' => _ = try self.add_token(&res, token.Type.LFT_PAREN, null),
                ')' => _ = try self.add_token(&res, token.Type.RGT_PAREN, null),

                '{' => _ = try self.add_token(&res, token.Type.LFT_BRACE, null),
                '}' => _ = try self.add_token(&res, token.Type.RGT_BRACE, null),

                ',' => _ = try self.add_token(&res, token.Type.COMMA, null),
                '.' => _ = try self.add_token(&res, token.Type.DOT, null),
                '+' => _ = try self.add_token(&res, token.Type.PLUS, null),
                '-' => _ = try self.add_token(&res, token.Type.MINUS, null),
                ';' => _ = try self.add_token(&res, token.Type.SEMICOLON, null),
                '/' => {
                    if (self.match('/')) {
                        var p: u8 = self.advance();
                        while (p != '\n' and p != 0) : (p = self.advance()) {} // skip comment
                    } else {
                        _ = try self.add_token(&res, token.Type.SLASH, null);
                    }
                },
                '*' => _ = try self.add_token(&res, token.Type.STAR, null),

                '=' => _ = try self.add_token(
                    &res,
                    if (self.match('=')) token.Type.EQUAL_EQUAL else token.Type.EQUAL,
                    null,
                ),

                '!' => _ = try self.add_token(
                    &res,
                    if (self.match('=')) token.Type.BANG_EQUAL else token.Type.BANG,
                    null,
                ),

                '>' => _ = try self.add_token(
                    &res,
                    if (self.match('=')) token.Type.GREATER_EQUAL else token.Type.GREATER,
                    null,
                ),

                '<' => _ = try self.add_token(
                    &res,
                    if (self.match('=')) token.Type.LESSER_EQUAL else token.Type.LESSER,
                    null,
                ),

                '"' => {
                    var p = self.advance();
                    while (p != '"') : (p = self.advance()) {
                        if (self.peek() == 0) {
                            return Error.UNTERMINATED_STRING;
                        }

                        if (self.peek() == '\n') {
                            self.add_line();
                        }
                    }

                    _ = try self.add_string(&res);
                },

                '\n' => self.add_line(),

                ' ', '\t', '\r' => {},
                else => {
                    if (is_alpabhet(char)) {
                        while (is_alphanumeric(self.peek())) : (_ = self.advance()) {}
                        try self.add_identifier(&res, reserved_keyword);

                        continue;
                    }

                    if (is_numeric(char)) {
                        while (is_numeric(self.peek())) : (_ = self.advance()) {}

                        if (self.peek() == '.' and is_numeric(self.peek_next())) {
                            _ = self.advance();
                            while (is_numeric(self.peek())) : (_ = self.advance()) {}
                        }

                        _ = try self.add_number(&res);
                        continue;
                    }

                    return Error.INVALID_TOKEN;
                },
            }
        }

        // eof
        _ = try res.append(token.Token{
            .lexeme = &[_]u8{0},
            .type = token.Type.EOF,
            .literal = null,
            .line = self.current,
        });

        return res.clone();
    }

    fn add_line(self: *Scanner) void {
        self.line += 1;
        self.col = 0;
    }

    fn next(self: *Scanner) void {
        self.current += 1;
        self.col += 1;
    }

    fn add_token(self: *Scanner, list: *token.List, t: token.Type, literal: ?token.Literal) !void {
        _ = try list.append(token.Token{
            .lexeme = self.source[self.start..self.current],
            .type = t,
            .literal = literal,
            .line = self.line,
        });
    }

    fn add_string(self: *Scanner, list: *token.List) !void {
        _ = try list.append(token.Token{
            .lexeme = self.source[self.start..self.current],
            .type = token.Type.STRING,
            .literal = token.Literal{ .string = self.source[self.start + 1 .. self.current - 1] },
            .line = self.line,
        });
    }

    fn add_number(self: *Scanner, list: *token.List) !void {
        const lexeme = self.source[self.start..self.current];
        const number = try std.fmt.parseFloat(f32, lexeme);
        _ = try list.append(token.Token{
            .lexeme = lexeme,
            .type = token.Type.NUMBER,
            .literal = token.Literal{ .number = number },
            .line = self.line,
        });
    }

    fn add_identifier(self: *Scanner, list: *token.List, keywords: std.StringHashMap(token.Type)) !void {
        const lexeme = self.source[self.start..self.current];
        if (keywords.get(lexeme)) |t| {
            return self.add_token(list, t, null);
        }

        _ = try list.append(token.Token{
            .lexeme = lexeme,
            .type = token.Type.IDENTIFIER,
            .literal = token.Literal{ .identifier = lexeme },
            .line = self.line,
        });
    }

    fn is_alpabhet(char: u8) bool {
        return (char >= 'a' and char <= 'z') or
            (char >= 'A' and char <= 'Z');
    }

    fn is_numeric(char: u8) bool {
        return (char >= '0' and char <= '9');
    }

    fn is_alphanumeric(char: u8) bool {
        return is_alpabhet(char) or is_numeric(char);
    }
};

pub fn init(source: []const u8) Scanner {
    return Scanner{
        .source = source,
        .current = 0,
        .start = 0,
        .line = 0,
        .col = 0,
    };
}
