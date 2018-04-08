import org.jrubyparser.CompatVersion;
import org.jrubyparser.Parser;
import org.jrubyparser.ast.*;
import org.jrubyparser.parser.ParserConfiguration;
import java.io.StringReader;

public class ParseSomething {

    public static void main(String[] args) {
        String codeString = "def foo(bar)\n bar\n end\n foo('astring')";

        Node node = parseContents(codeString);
        System.out.println(node);
    }

    public static Node parseContents(String string) {
        Parser rubyParser = new Parser();
        StringReader in = new StringReader(string);
        CompatVersion version = CompatVersion.RUBY1_8;
        ParserConfiguration config = new ParserConfiguration(0, version);
        return rubyParser.parse("<code>", in, config);
    }
}
