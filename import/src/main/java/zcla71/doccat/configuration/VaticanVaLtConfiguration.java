package zcla71.doccat.configuration;

import java.nio.charset.Charset;

import org.springframework.batch.item.file.FlatFileItemReader;
import org.springframework.batch.item.file.builder.FlatFileItemReaderBuilder;
import org.springframework.context.annotation.Configuration;
import org.springframework.core.io.ClassPathResource;

import zcla71.doccat.model.Download;

@Configuration
public class VaticanVaLtConfiguration {
    public FlatFileItemReader<Download> reader() {
        return new FlatFileItemReaderBuilder<Download>()
            .name("VaticaVaLtReader")
            .resource(new ClassPathResource("VaticanVaLt.json")
            .getContentAsString(Charset.forName("UTF8")));
    }
}
