#!/bin/bash
# Script để chạy unit tests với Java 17

export JAVA_HOME=/Users/duy/Library/Java/JavaVirtualMachines/corretto-17.0.10/Contents/Home

echo "🧪 Chạy Unit Tests với Java 17..."
echo "Java version:"
"$JAVA_HOME/bin/java" -version

echo ""
echo "📊 Running tests..."
mvn clean test

echo ""
echo "📄 Generating HTML report..."
mvn surefire-report:report

echo ""
echo "✅ Done! Xem báo cáo tại:"
echo "   - target/surefire-reports/ (XML reports)"
echo "   - target/site/surefire-report.html (HTML report)"
echo ""
echo "Mở HTML report:"
echo "   open target/site/surefire-report.html"
