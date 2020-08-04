% function main()
%     file = 'Image/APC_0001_ex.dng';
%     img = dng2img(file);
%     imagesc(uint8(img), [0 255])
% %     imshow(img)
% end
%     

function out =  dng2img(file)
    % ファイル情報の取得
    info = imfinfo(file);
    info.SubIFDs{1};

    % Tiff形式で読み込み
    % cfa: 浮動小数点形式のセンサデータ
    % [h, w]: 画像のサイズを入れておく
    % 独自形式のtiffの部分でエラーを吐くので警告を切る。
    warning('off', 'tifflib:TIFFReadDirectory');
    t = Tiff(file,'r');
    offsets = getTag(t, 'SubIFD');
    setSubDirectory(t, offsets(1));
    cfa = single(read(t));
    [h, w] = size(cfa);
    close(t);

    %% Bayer CFA patterの作成
    % r, g, b
    cfa_pattern = cat(3, [1 0; 0 0], [0 1; 1 0], [0 0; 0 1]);
    % cfa_patternを画像サイズ分繰り返す
    im_cfa = repmat(cfa_pattern, h/2, w/2) .* cfa;
    % r, bのカーネル, gのカーネルをそれぞれ作成
    rb_kernel = [1 2 1; ...
                 2 4 2; ...
                 1 2 1] ./ 4;
    g_kernal  = [0 1 0; ...
                 1 4 1; ...
                 0 1 0] ./ 4;
    kernels = cat(3, rb_kernel, g_kernal, rb_kernel);
    for ch = 1:3
        rgb(:,:,ch) = conv2(im_cfa(:,:,ch), kernels(:,:,ch), 'same');
    end

    %% RAWデータに含まれるWhite LevelとBlack Levelよりデータの正規化、照度を調整
    bl = info.SubIFDs{1}.BlackLevel;
    wl = info.SubIFDs{1}.WhiteLevel;
    rgb = (rgb - bl) / (wl - bl);

    %% ホワイトバランスの調整
    % 各色まとめて一行にする, r, g, bそれぞれの合計3列のベクトルを作成
    rgb_stripe = reshape(rgb, [], 3);
    wb = info.AsShotNeutral(2)./info.AsShotNeutral;
    rgb_stripe = rgb_stripe .* wb;
    rgb = reshape(rgb_stripe, h , w, []);

    %% 明るさ(ゲイン)の調整
    gain = (1/4) / mean(rgb(:));
    rgb4 = gain .* rgb;
    rgb4(rgb4 > 1) = 1;
    rgb4(rgb4 < 0) = 0;

    %% 画像を8bit(255)階長で示す
    threshold = 0.0031308;
    out = rgb4;
    out(rgb4 <= threshold) = 12.92 * rgb4(rgb4 <= threshold);
    out(rgb4 >  threshold) = 1.055 * rgb4(rgb4 >  threshold) .^ (1/2.4) - 0.055;
    out = 255 * out;
end