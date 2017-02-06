#!/usr/bin/env python2.7

import argparse
import re
import sys

# This is a custom modification of the TreebankWordTokenizer.
# The original tokenizer replaced double quotes with `` and ''.
# Since do not want to add new symbols to the sentences, we keep
# the double quotes symbols.
# This also makes trivial the function span_tokens, which
# TreebakWordTokenizer did not have implemented.
# Adapted from: http://www.nltk.org/_modules/nltk/tokenize/treebank.html
class CustomTreebankWordTokenizer:
    #starting quotes
    STARTING_QUOTES = [
        (re.compile(ur'([ (\[{<])"'), ur'\1 " '),
    ]

    #punctuation
    PUNCTUATION = [
        (re.compile(ur'[;@#$%&.,/\u20AC$-]'), ur' \g<0> '),
        (re.compile(ur'([^\.])(\.)([\]\)}>"\']*)\s*$'), r'\1 \2\3 '),
        (re.compile(ur'[?!]'), ur' \g<0> '),
        (re.compile(ur"([^'])' "), ur"\1 ' "),
    ]

    #parens, brackets, etc.
    PARENS_BRACKETS = [
        (re.compile(ur'[\]\[\(\)\{\}\<\>]'), ur' \g<0> '),
        (re.compile(ur'--'), ur' -- '),
    ]

    #ending quotes
    ENDING_QUOTES = [
        (re.compile(ur'"'), ' " '),              # This line changes: do not replace "
        (re.compile(ur'(\S)(\'\')'), ur'\1 \2 '),
    ]

    CONTRACTIONS = [
        (re.compile(ur"([^' ]')([^' ])"), ur'\1 \2'),
    ]

    def tokenize(self, text):
        text = unicode(text)
        for regexp, substitution in self.STARTING_QUOTES:
            text = regexp.sub(substitution, text, re.UNICODE)

        for regexp, substitution in self.PUNCTUATION:
            text = regexp.sub(substitution, text, re.UNICODE)

        for regexp, substitution in self.PARENS_BRACKETS:
            text = regexp.sub(substitution, text, re.UNICODE)

        #add extra space to make things easier
        text = " " + text + " "

        for regexp, substitution in self.ENDING_QUOTES:
            text = regexp.sub(substitution, text, re.UNICODE)

        for regexp, substitution in self.CONTRACTIONS:
            text = regexp.sub(substitution, text, re.UNICODE)

        tokens = []
        for tok in text.split():
            if not re.match(ur'^[A-Z0-9]+$', tok, re.UNICODE):
                tokens.append(tok)
            else:
                for t in re.split(ur'([A-Z0-9])', tok, re.UNICODE):
                    if len(t) > 0: tokens.append(t)

        return tokens

    def span_tokens(self, text):
        text = unicode(text)
        tokens = self.tokenize(text)
        spans = []
        i = 0
        for tok in tokens:
            spans.append((i, i + len(tok)))
            i += len(tok)
            if i < len(text) and re.match(ur'^\s$', text[i], re.UNICODE):
                i += 1
        return spans


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(
        'input', type=argparse.FileType('r'), nargs='?', default=sys.stdin,
        help='input text file')
    parser.add_argument(
        'output', type=argparse.FileType('w'), nargs='?', default=sys.stdout,
        help='output text file')
    parser.add_argument(
        '--write-boundaries', type=argparse.FileType('w'), default=None,
        help='write token boundaries to this file')
    parser.add_argument(
        '--boundary', type=str, default='\\s',
        help='use this token as the boundary token')
    args = parser.parse_args()

    tokenizer = CustomTreebankWordTokenizer()
    lexicon = {}
    for line in args.input:
        line = re.sub(ur'\s+', ' ', line.strip().decode('utf-8'), re.UNICODE)
        spans = tokenizer.span_tokens(line)
        tokens = map(lambda x: line[x[0]:x[1]], spans)
        args.output.write((u' '.join(tokens) + u'\n').encode('utf-8'))
        if args.write_boundaries is not None:
            for i in xrange(len(tokens)):
                pron = [args.boundary, tokens[i], args.boundary]
                if i > 0 and spans[i][0] == spans[i - 1][1]:
                    pron = pron[1:]
                if i < len(tokens) - 1 and spans[i][1] == spans[i + 1][0]:
                    pron = pron[:-1]
                pron = tuple(pron)
                if tokens[i] not in lexicon: lexicon[tokens[i]] = {}
                if pron not in lexicon[tokens[i]]: lexicon[tokens[i]][pron] = 1
                else: lexicon[tokens[i]][pron] += 1

    if args.write_boundaries:
        lexicon = lexicon.items()
        lexicon.sort()
        for (token, prons) in lexicon:
            for pron, cnt in prons.iteritems():
                args.write_boundaries.write((u'%s\t%d\t%s\n' % (token, cnt, ' '.join(pron))).encode('utf-8'))
        args.write_boundaries.close()

    args.output.close()
