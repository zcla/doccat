package zcla71.doccat.processor;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.batch.item.ItemProcessor;
import org.springframework.lang.NonNull;
import org.springframework.lang.Nullable;

import zcla71.doccat.model.Download;

public class VaticanVaLtProcessor implements ItemProcessor<Download, Download> {
    private static final Logger log = LoggerFactory.getLogger(Download.class);

    @Override
    @Nullable
    public Download process(@NonNull Download download) throws Exception {
        log.info(download.toString());
        return download;
    }
}
