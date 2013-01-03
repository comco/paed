// Written in the D Programming Language

// Ukkonen's suffix tree algorithm with a sentinel
// durty, durty working version - still having much to polish
// written by comco, 2013

import std.stdio;
import std.string;
import std.array;

const int max_i = 256;

class Edge {
    string label; // dlang strings support slicing
    Node dest;
    
    this(string label, Node dest) {
        this.label = label;
        this.dest = dest;
    }

    int length() {
        return label.length;
    }
}

class Node {
    static int counter = 0;

    Edge[max_i] edges;
    Node link;
    int id;

    this(Node link = null) {
        this.link = link;
        this.id = counter++;
    }

    Edge opIndex(char c) {
        //return edges[c - 'a'];
        return edges[c];
    }

    void add(Edge e) {
        //edges[e.label[0] - 'a'] = e;
        edges[e.label[0]] = e;
    }
}    

class UkkonenSuffixTree {
    Node nil, root, activeNode;
    char activeChar;
    int activeLength;

    this() {
        // construct a sentinel - a special node
        // connecting to root
        nil = new Node;
        root = new Node(nil);
        nil.link = nil;
        nil.edges = new Edge("*", root);

        activeNode = root;
    }

    // dump as graphviz dot
    void dumpDot() {
        int nid = -1;
        writeln("0 [shape=circle, label=\"^\"];");
        writeln("1 [shape=circle, peripheries=2, label=\"\"];");
        writeln("0 -> 1 [label=\"*\"];");
        
        void dfs(Node curr) {
            writefln("%d -> %d [style=dotted, weight=0];", curr.id, curr.link.id);
            for (int i = 0; i < max_i; ++i) {
                Edge e = curr.edges[i];
                if (e) {
                    if (e.dest) {
                        writefln("%d [shape=circle, label=\"\"];", e.dest.id);
                        writefln("%d -> %d [label=\"%s\"]", curr.id, e.dest.id, e.label);
                        dfs(e.dest);
                    } else {
                        writefln("%d [shape=square, label=\"\"];", nid);
                        writefln("%d -> %d [label=\"%s\"];", curr.id, nid, e.label);
                        --nid;
                    }
                }
            }
        }

        dfs(root);
    }

    Edge activeEdge() {
        return activeNode[activeChar];
    }

    string activeLabel() {
        return activeEdge.label;
    }

    bool matches(char c) {
        if (activeLength > 0) {
            return activeLabel[activeLength] == c;
        } else {
            return (activeNode[c] !is null);
        }
    }

    void advance(char c) {
        if (activeLength == 0) {
            activeChar = c;
        }
        ++activeLength;
        if (activeLength == activeEdge.length) {
            activeNode = activeEdge.dest;
            activeLength = 0;
        }
    }

    Node branch(string label) {
        Node next;
        if (activeLength == 0) {
            next = activeNode;
        } else {
            next = new Node(nil);
        }        
        next.add(new Edge(label, null));
        if (next != activeNode) {
            next.add(new Edge(activeLabel[activeLength .. $], activeEdge.dest));
            activeNode.add(new Edge(activeLabel[0 .. activeLength], next));
        }
        return next;
    }

    void fix(string label) {
        assert(label.length == activeLength);
        if (activeLength > 0) {
            activeChar = label[0];
            if (activeLabel.length <= activeLength) {
                int activeLabelLength = activeLabel.length;
                activeLength -= activeLabelLength;
                activeNode = activeEdge.dest;
                fix(label[activeLabelLength .. $]);
            }
        }
    }

    void follow() {
        Node next = activeNode.link;
        if (activeLength > 0) {
            string label = activeLabel[0 .. activeLength];
            activeNode = next;
            fix(label);
        } else {
            activeNode = next;
        }
    }

    // The whole algorithm - simplified by the sentinel node
    // just 12 lines of code!
    void addSuffixes(string text) {
        foreach (int i, char c; text) {
            Node prev = null;
            while (!matches(c)) {
                Node next = branch(text[i .. $]);
                if (prev) {
                    prev.link = next;
                }
                follow();
                prev = next;
            }
            advance(c);
        }
    }
}

void main() {
    writeln("/*");
    auto t = new UkkonenSuffixTree();
    t.addSuffixes("umbabarumba$");
    writeln("*/");
    writeln("digraph g {");
    writeln("rankdir=LR;");
    t.dumpDot();
    writeln("}");
}

